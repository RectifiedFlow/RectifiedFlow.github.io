---
layout: distill
title: "Flow to Diffusion: Langevin is a Guardrail" 
description: It is known that we can convert between diffusion (SDE) and flow (ODE) models at inference time without rettraining? How is this possible? What are the pros and cons adding diffusion noise to flows?
tags: tutorial
giscus_comments: true
date: 2024-12-7 10:00:00
featured: true
mermaid:
  enabled: true
  zoomable: true
code_diff: true
map: true
chart:
  chartjs: true
  echarts: true
  vega_lite: true
tikzjax: true
typograms: true

thumbnail: /assets/img/thumbnail/stochastic_sampler_thumbnail.png
thumbnail_alt: "Thumbnail of Stochastic Samplers"

bibliography: reference.bib

authors:
  - name: Xixi Hu
    url: "mailto:rectifiedflow@gmail.com"
    affiliations:
      name: UT Austin
  - name: Runlong Liao
  - name: Bo Liu
  - name: Qiang Liu

# 可选的目录配置
toc:
  - name: "Overview"
  - name: "Stochastic Samplers = RF + Langevin"
  - name: "SDEs with Tweedie's formula"
  - name: "Diffusion May Cause Over-Concentration"
---

<!-- 
<div class="hero">
  <img src="/assets/img/teaser_post3.png" alt="Rectified Flow Overview" style="width: 100%; max-height: 500px; object-fit: cover; border-radius: 10px; margin-bottom: 20px;">
</div>
--> 

## Overview
Rectified flow (RF) yields an deterministic ODE (a.k.a. flow) model, of the form $$\mathrm d Z_t = v_t(Z_t)\mathrm d t$$, which generates the data $$Z_1$$ starting from an initial noise $$Z_0$$. This approach offers a simplification compared to diffusion models that on a stochastic differential equation (SDE) to generate data from noise, such as DDPM and score-based models. 

However, the boundary between flow and diffusion models has been known to be blurry since the work of DDIM and probability-flow ODEs, which showed that it is possible to convert SDEs to ODEs during the post-training phase, without requiring re-training of the model. Now taking the ODE models, it is also possible to revert the process and convert the RF ODE to SDE to obtain stochastic samplers at inference time. Several questions arises:  

1. Why and how is it possible to convert between SDEs and ODEs? What is the intuition?

2. Why would we bother to add diffusion noise? What are the pros and cons?

We will explore these questions in this blog. For a more detailed discussion, see Chapter 5 of the [Rectified Flow Lecture Notes](https://github.com/lqiang67/rectified-flow/tree/main/pdf). Related works include DDIM<d-cite key="song2020denoising"></d-cite>, score-based SDEs<d-cite key="song2020score"></d-cite>, EDM<d-cite key="karras2022elucidating"></d-cite>. 


## Stochastic Samplers = RF + Langevin

Given a coupling $$(X_0, X_1)$$ of noise and data points, rectified flow defines an interpolation process, such as $$X_t = t X_1 + (1 - t) X_0$$, and "rectifies" or "causalizes" it to yield an ODE model $$\mathrm{d} Z_t = v_t(Z_t) \, \mathrm{d} t$$ initialized from $$Z_0 = X_0.$$ 
The velocity field is given by $$v_t(z) = \mathbb{E}[\dot{X}_t \mid X_t = z],$$ which is estimated by minimizing the loss $$\mathbb{E}_{t, X_0, X_1} [ \| \dot{X}_t - v_t(X_t) \|^2 ].$$

The key property of RF ODE is the marginal preservation property: the distribution of $$Z_t$$ on the ODE trajectory matches the distribution of $$X_t$$ on the interpolation path at each time $$t$$. This is ensured by the construction of the velocity field $$v_t$$. As a result, the final output $$Z_1$$ of the ODE follows the same distribution as $$X_1$$, the target data distribution. This follows an inductive principle: if the distributions of $$X_t$$ and $$Z_t$$ match up to a given time, the construction of $$v_t$$ ensures they will continue to match at the next (infinitesimal) step. By being "scheduled to do the right thing at the right time," the process guarantees the correct final result.

An obvious problem of this is that, in practice, errors can accumulate over time as we solve the ODE $$\mathrm{d} Z_t = v_t(Z_t) \mathrm{d} t$$. These errors arise from model approximations and numerical discretization, causing drift between the estimated distribution and the true distribution. The issue can compound: if the estimated trajectory $$\hat{Z}_t$$ deviates significantly from the distribution of $$X_t$$, the update direction $$v_t(\hat{Z}_t)$$ becomes less accurate. This happens because fewer data points are sampled in low-probability regions during training, where model inaccuracies are more pronounced.

To address this problem, we may introduce a feedback mechanism to correct the error. One such approach is to use Langevin dynamics. 

Let $$\rho_t$$ be the density function of $$X_t$$, representing the true distribution that we aim to follow at time $$t$$. At each time step $$t$$, we can in principle apply a short segment of Langevin dynamics to adjust the trajectory's distribution toward $$\rho_t$$:

$$
\mathrm{d} Z_{t, \tau} = \sigma_t^2 \nabla \log \rho_t(Z_{t, \tau}) \, \mathrm{d} \tau + \sqrt{2} \, \sigma_t \, \mathrm{d} W_\tau, \quad \tau \geq 0,
$$

where $$\tau$$ is a new time scale introduced for the Langevin dynamics, $$\sigma_t$$ controls the noise level, and $$\nabla \log \rho_t$$ adjusts the drift to steer the distribution toward high-probability regions of $$\rho_t$$. It is well known that Langevin dynamics converge to the target distribution as $$\tau \to \infty$$.

Fully simulating Langevin dynamics would require a double-loop algorithm, where the system must be simulated to equilibrium ($$\tau\to\infty$$) at each time $$t$$ before moving to the next time point.  

In rectified flow, however, the trajectory is already close to $$\rho_t$$ at each time step $$t$$. Therefore, a single step of Langevin dynamics can be sufficient to reduce the drift. This allows us to directly integrate Langevin corrections into the rectified flow updates, yielding a combined stochastic differential equation (SDE):

$$
\mathrm{d}\tilde{Z}_t = \underbrace{v_t(\tilde{Z}_t) \mathrm{d} t}_{\text{Rectified Flow}} + \underbrace{\sigma_t^2 \nabla \log \rho_t(\tilde{Z}_t) \mathrm{d} t + \sqrt{2} \sigma_t \mathrm{d}W_t}_{\text{Langevin Dynamics}}, \quad \tilde{Z}_0 = Z_0. 
$$

This combined SDE achieves two key objectives:

1. The **rectified flow** drives the generative process forward as intended.

2. The **Langevin component** acts as a negative feedback loop, correcting distributional drift without bias when $$\tilde{Z}_t$$ and $$\rho_t$$ are well aligned.

When the simulation is accurate, Langevin dynamics naturally remain in equilibrium, avoiding unnecessary changes to the distribution. However, if deviations occur, this mechanism guides the estimate back on track, enhancing the robustness of the inference process.

The figure below illustrates the score function $$\nabla \log \rho_t$$ along the SDE trajectories. We can see that $$\nabla \log \rho_t$$ points toward high-density regions, and hence can guid trajectories back to areas of higher probability whenever deviations occur.

<div class="l-body" style="text-align:center;">
  <img src="/assets/img/score_function_on_sde_traj.png" alt="cross" style="max-width:58%;" />
</div>

The figure below compares the results of two sampling methods. On the left, we show the result of the Euler discretization on the deterministic ODE applied to an insufficiently trained $v_t$ (due to early stopping), resulting in a significant presence of outliers. On the right, the Euler–Maruyama method is used to simulate the SDE, which effectively suppresses the outliers through the feedback mechanism introduced by the score functions.

<div class="l-body">
  <img src="/assets/img/euler_sde_compare.png" alt="cross" style="max-width:100%;margin-bottom: 20px" />
</div>

This correction mechanism seems to have effect on state-of-the-art text-to-image generation as well.
In this [recent work](https://arxiv.org/abs/2411.19415)<d-cite key="hu2024amo"></d-cite>, we find that stochastic samplers improves the text rendering qualities over deterministic samplers on SOTA models such as Flux -- it allows makes generated images better reflect the text in the prompt. The figure below highlights this improvement: on the left, applying the stochastic sampler to the Flux model consistently outperforms the deterministic Euler sampler in text rendering performance across all step sizes. On the right, we present qualitative examples showcasing the enhanced text rendering quality achieved with the stochastic sampler.


<div class="l-body">
  <img src="/assets/img/flux_text_rendering.png" alt="cross" style="max-width:100%;margin-bottom: 20px" />
</div>


## SDEs with Tweedie's formula 

In general, it may be necessary to estimate the score function $$\nabla \log \rho_t$$ in addition to the RF velocity $$v_t$$. However, in certain special cases, the score function can be estimated using $$v_t$$, thereby eliminating the need to retrain an additional model. This approach enables a training-free conversion between ODEs and SDEs.

Specifically, if the rectified flow is induced by an affine interpolation $$X_t = \alpha_t X_1 + \beta_t X_0$$, where $$X_0$$ and $$X_1$$ are independent (i.e., $$X_0 \perp\!\!\!\perp X_1$$) and $$X_0$$ follows a standard Gaussian distribution, then by Tweedie's formula, we have 

$$
\nabla \log \rho_t(x) = -\frac{1}{\beta_t} \mathbb{E}[X_0 \mid X_t = x].
$$

On the other hand, the RF velocity is given by 

$$
v_t(x) = \mathbb{E}[\dot{X}_t \mid X_t = x] = \mathbb{E}[\dot{\alpha}_t X_1 + \dot{\beta}_t X_0 \mid X_t = x],
$$

where $$X_t = \alpha_t X_1 + \beta_t X_0$$. 

Using this, we can express $$\mathbb{E}[X_0 \mid X_t = x]$$ in terms of $$v_t(x)$$ and obtain 

$$
\nabla \log \rho_t(x) = \frac{\alpha_t v_t(x) - \dot{\alpha}_t x }{\lambda_t \beta_t},
$$

where $$\lambda_t = \dot{\alpha}_t \beta_t - \alpha_t \dot{\beta}_t$$. 

As a result, the SDE takes the form 

$$
\mathrm d Z_t = v_t(Z_t)\mathrm d t +  \gamma (\alpha_t v_t (x) - \dot \alpha_t x) \mathrm{d} t +  \sqrt{2 \lambda_t \beta_t \gamma_t} \mathrm{d} W_t, 
$$

where we set $$\sigma_t^2 = \lambda_t \beta_t \gamma_t$$. 

In the case straight interpolation $$X_t = t X_1 + (1-t)X_0$$, we have $$\nabla \log \rho_t(x) = \frac{t v_t(x) - x}{1-t}$$, yielding 

$$
\mathrm d Z_t = v_t(Z_t)\mathrm d t +  \gamma (t v_t (x) -  x) \mathrm{d} t +  \sqrt{2 \gamma (1-t) } \mathrm{d} W_t. 
$$


The SDE of DDPM and the score-based SDEs is be recovered 
when $$\gamma_t = 1 / \alpha_t$$ and $$\alpha^2_t + \beta_t^2 = 1$$, yielding 

$$
\mathrm{d} Z_t = 2 v_t(Z_t) \, \mathrm{d} t - \frac{\dot{\alpha}_t}{\alpha_t} Z_t \, \mathrm{d} t + \sqrt{2  \frac{\dot \alpha_t}{\alpha_t}} \mathrm{d} W_t.
$$


## Diffusion May Cause Over-Concentration 

Although things work out nicely in theory, we need to be careful that the introduced score function $$\nabla \log \rho_t(x)$$ itself has errors, and it may introduce undesirable effects if we rely on it too much (with a large $$\sigma_t$$). 
This is indeed the case in practice. As shown in the figure below, when we increase the noise magnitude $$\sigma_t$$,  the generated samples to cluster closer to the centers of the Gaussian modes.

<div class="l-body">
  <img src="/assets/img/sde_concentrate_2d.png" alt="cross" style="max-width:100%;margin-bottom: 20px" />
</div>


So, large diffusion yields more concentrate results. This is rather counter-intuitive. Why is it the case? 

To see this, assume the estimated velocity field is $$\hat v_t \approx v_t$$. The resulting estimated score function from Tweedie's formula is 

$$
\nabla \log \hat \rho_t(x) = \frac{1}{\lambda_t \beta_t} \left( \alpha_t \hat v_t(x) - \dot{\alpha}_t x \right). 
$$

Because $$\beta_t$$ must converge to 0 as $$t \to 1$$, the estimated score function $$\nabla \log \hat{\rho}_t(x)$$ is likely to diverge to infinity in this limit. This divergence leads to a significant overestimation of the true magnitude of $$\nabla \log \rho_t(x)$$, which may be finite. As a result, the outputs of the SDE tend to become overly concentrated. This occurs because $$\nabla \log \rho_t(x)$$ increasingly points toward the centers of mass clusters, or the local optima of the probability density. 

In other words, the Langevin guardrail may become *excessive*, causing over-concentration. Note that the deciding factor here is the score function $$\nabla \log \rho_t(x)$$, not the introduction of noise, as one might initially assume. The noise component, as part of Langevin dynamics, merely compensates for the concentration effects induced by $$\nabla \log \rho_t(x)$$, rather than being the primary driver of those effects.

In the context of text-to-image generation, this over-concentration effect often produces overly smoothed images, which may appear cartoonish. Such over-smoothing eliminates fine details and high-frequency variations, resulting in outputs with a blurred appearance. The figure below illustrates these differences: samples generated using the Euler sampler exhibit more high-frequency details, as seen in the texture of the parrot's feathers and the structure of the smoke.

<div class="l-body">
  <img src="/assets/img/euler_sde_comp_flux.png" alt="cross" style="max-width:100%;margin-bottom: 20px" />
</div>

