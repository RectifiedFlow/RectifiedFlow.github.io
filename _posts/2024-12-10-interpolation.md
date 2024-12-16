---
layout: distill
title: All Flows are One Flow
description: Affine Interpolations Result in Equivalent Rectified Flows
tags: tutorial
giscus_comments: true
date: 2024-12-10 10:00:00
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

# 如需添加作者信息，在下方添加authors字段
authors:
  - name: Runlong Liao
    url: "mailto:rectifiedflow@googlegroups.com"
    affiliations:
      name: UT Austin
  - name: Xixi Hu
  - name: Bo Liu
  - name: Qiang Liu

# 如果有文献，请指定bibliography文件
bibliography: 2024-12-10-interpolation.bib

# 可选的目录配置
toc:
  - name: "Point-wisely Transformable Interpolations"
    subsections:
      - name: "Equivalence of Affine Interpolations"
      - name: "Converting Pretrained RF Velocity"
  - name: "Implications on Loss Functions"
    subsections:
      - name: "Straight vs Spherical: Same Train Time Weight"
---

<div class="hero">
  <img src="/assets/img/teaser_post2.png" alt="Rectified Flow Overview" style="width: 100%; max-height: 500px; object-fit: cover; border-radius: 10px; margin-bottom: 20px;">
</div>
This blog introduces the equivalent relationships between rectified flows induced from different affine interpolations, based on Chapter 3 of these [lecture notes](https://github.com/lqiang67/rectified-flow/tree/main/pdf).  Related observations and discussion can also be found in <d-cite key="karras2022elucidating,kingma2024understanding,shaulbespoke,gao2025diffusionmeetsflow"></d-cite>.

## Overview

Given an arbitrary coupling $$(X_0, X_1)$$ of source distribution $$\pi_0$$ and target distribution $$\pi_1$$, recall that Rectified Flow learns a ODE

$$
\mathrm d Z_t = v_t(Z_t),
$$

which, starts from $$Z_0=X_0$$, leads to $$Z_1 = X_1$$. This velocity is learned by minimizing the mean square loss from the slope of an interpolation process:

$$
\min_v \int _0 ^1 \mathbb E \left[\left\| \dot X_t - v_t(X_t)\right\| 
\right] \mathrm d t,
$$

where $$\{X_t\} = \{X_t: t\in [0,1]\}$$ is an interpolation process connecting $$X_0$$ and $$X_1$$, and $$\dot X_t$$ denotes its time derivative.

Theoretically, $$\{X_t\}$$ can be any smooth interpolation between source and target distributions. Here, we go over three types of interpolations:

1. *Straight interpolation*, as used in <d-cite key="liu2022flow,lipman2022flow,albergo2023stochastic"></d-cite>:

   $$
   X_t = tX_1 + (1-t) X_0.
   $$

   This are straight lines connecting $$\pi_0$$ and $$\pi_1$$ at a constant speed $$\dot X_t = X_1 - X_0.$$

2. *Spherical linear interpolation* (*slerp*), employed by iDDPM <d-cite key="nichol2021improved"></d-cite>: 

   $$
   X_t = \sin\left(\frac{\pi}{2} t\right)X_1  +   \cos\left(\frac{\pi}{2} t\right)X_0,
   $$

   which travels along the shortest great-circle arc on a sphere at a constant speed.

3. *DDIM interpolation*,<d-cite key="song2020denoising"></d-cite> a spherical interpolation but with a non-uniform speed defined by $\alpha_t$:

   $$
   X_t = \alpha_t X_1 + \sqrt{1-\alpha_t^2} X_0,
   $$

   where $$\alpha_t = \exp\bigl(-\frac{1}{4}a(1-t)^2 - \tfrac{1}{2}b(1-t)\bigr)$$, and $$a=19.9,b=0.1$$ by default.

Different methods employ these or other interpolation schemes. One might suspect that such choices, by influencing the learned RF velocity, must be finalized during training, because the velocity field could significantly affect inference performance and speed. However, as we will show, this need not be the case.

In this blog, we'll show that—under mild constraints on the interpolation scheme—it is possible to convert between those different interpolation schemes *after* training, at inference time. Moreover, we demonstrate that these interpolations yield essentially *equivalent* Rectified Flow dynamics and identical couplings. Thus, it suffices to adopt a simple interpolation, such as the straight line $$X_t = t X_1 + (1-t) X_0$$, and later recover all other interpolation paths through simple transformations. This flexibility shifts our attention to the sampling stage, where different interpolation schemes can be freely adopted, while their differences remain relatively minor during training.

## Point-wisely Transformable Interpolations

Generally, for any interpolation, we can define pointwise transformability:

> **Definition 1**. Consider any two interpolation processes $$\{X_t : t \in [0,1]\}$$ and $$\{X'_t : t \in [0,1]\}$$. We say they are **pointwise transformable** if there exist differentiable maps $$\tau: [0,1] \to [0,1]$$ and $$\phi: [0,1] \times \mathbb{R}^d \to \mathbb{R}^d$$ such that $$\phi_t$$ is invertible for every $$t \in [0,1]$$ and 
> 
> $$
> X'_t = \phi_t(X_{\tau_t}) \quad \text{for all } t \in [0,1].
> $$
> 

For Rectified Flows induced from those pointwise transformable interpolations, we have:

> **Theorem 1**. Suppose two interpolations $$\{X_t\}$$ and $$\{X'_t\}$$ are pointwise transformable and constructed from the same coupling $$(X_0, X_1) = (X'_0, X'_1)$$. Let $$\{v_t\}$$ and $$\{v'_t\}$$ be their corresponding Rectified Flow velocity fields, and $$\{Z_t\}$$ and $$\{Z'_t\}$$ their Rectified Flows, respectively. Let $$\phi$$ and $$\tau$$ be the transformation maps between $$\{X_t\}$$ and $$\{X_t'\}$$ with $$\tau_0 = 0$$ and $$\tau_1 = 1$$. Then:
>
> 1. The same pointwise transformation that maps their interpolations $$\{X_t\} \to\{X'_t\}$$ also maps their Recitied Flows $$\{Z_t\}\to\{Z'_t\}$$:
> 
>    $$
>    Z'_t = \phi_t(Z_{\tau_t}) \quad \text{for all } t \in [0,1].
>    $$
>
> 2. The two rectified flows produce the same coupling:
> 
>    $$
>    (Z_0, Z_1) = (Z'_0, Z'_1).
>    $$
>
> 3. Their velocity fields are related by:
> 
>    $$
>    v'_t(x) = \partial_t \phi_t(\phi_t^{-1}(x)) + \bigl(\nabla \phi_t(\phi_t^{-1}(x))\bigr)^\top v_{\tau_t}(\phi_t^{-1}(x)) \dot{\tau}_t. \tag{1}
>    $$

In other words, define $$\{X'_t\} := \texttt{Transform}(\{X_t\})$$ to represent the pointwise transformation of the interpolation. The operation $$\texttt{Rectify}(\cdot)$$, which maps an interpolation $$\{X_t\}$$ to its corresponding rectified flow $$\{Z_t\}$$, is **equivariant** under pointwise transformations:

$$
\texttt{Rectify}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{Rectify}(\{X_t\})).
$$

### Equivalence of Affine Interpolations

In practice, one often considers interpolations of the form

$$
X_t = \alpha_t X_1 + \beta_t X_0,
$$

where $\alpha_t$ and $\beta_t$ are monotonic on $t\in[0,1]$ and satisfy the boundary conditions:

$$
\alpha_0=\beta_1=0, \quad \alpha_1 = \beta_0 = 1.
$$

All such interpolations are *affine*. For this class of interpolations, the transformation maps $$\phi$$ and $$\tau$$ reduce to scalar transformations. In fact, **all affine interpolations are pointwise transformable** by appropriately scaling both time and the input. Consequently, their corresponding rectified flows can also be related through the same pointwise transformations, ultimately producing the same rectified couplings. This result aligns with observations made by other authors<d-cite key="karras2022elucidating,kingma2024understanding,shaulbespoke,gao2025diffusionmeetsflow"></d-cite>. 

> **Proposition 1**. Consider two affine interpolation processes derived from the same coupling $$(X_0, X_1)$$:
> $$
> X_t = \alpha_t X_1 + \beta_t X_0 \quad \text{and} \quad X_t' = \alpha_t' X_1 + \beta_t' X_0.
> $$
> 
>Then there exist scalar functions $$\tau_t$$ and $$\omega_t$$ such that
> 
>$$
> X_t' = \frac{1}{\omega_t} X_{\tau_t}, \quad \forall t \in [0,1],
> $$
> 
>where $$\tau_t$$ and $$\omega_t$$ are determined by solving
> 
>$$
> \frac{\alpha_{\tau_t}}{\beta_{\tau_t}} = \frac{\alpha'_t}{\beta'_t}, \quad \omega_t = \frac{\alpha_{\tau_t}}{\alpha'_t} = \frac{\beta_{\tau_t}}{\beta'_t}, \quad \forall t \in (0, 1) \tag{2}
> $$
> 
>under the boundary conditions
> 
>$$
> \omega_0 = \omega_1 = 1, \quad \tau_0 = 0, \quad \tau_1 = 1.
> $$
> 
>Uniqueness of the solution $$(\tau_t, \omega_t)$$ follows because $$\alpha'_t/\beta'_t \geq 0$$ and $$\alpha_t/\beta_t$$ is strictly increasing for $$t \in [0,1]$$. Thus, for any two affine interpolations of the same coupling, there is a unique pointwise transformation that relates them.

In practice, the time scaling function $$\tau_t$$ can be determined in two ways. For simpler cases, $$\tau_t$$ can be derived analytically. For more complex scenarios, a [simple binary search](https://github.com/lqiang67/rectified-flow/blob/main/rectified_flow/flow_components/interpolation_convertor.py) can be employed to approximate $$\tau_t$$. The figure below illustrates the $$\tau$$ and $$\phi$$ transformations that convert DDIM to spherical interpolation, and straight interpolation to spherical. Note that when converting DDIM to spherical interpolation, the only difference is in the time scaling—$$\omega_t$$ remains constant at $$1$$.

<div class="l-body-outset" style="display: flex;">
  <iframe src="{{ 'assets/plotly/interp_tau_ddim_spherical.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="430px" 
          width="49%"></iframe>
  <iframe src="{{ 'assets/plotly/interp_tau_straight_spherical.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="430px" 
          width="49%"></iframe>
</div>
Substituting the notion of $$\tau$$ and $$\omega$$ into Theorem 1, we have:

> **Example 1.** Converting straight interpolation into affine one.
>
> Consider the straight interpolation $$X_t=tX_1 + (1-t)X_0$$ for which $$\alpha_t=t$$ and $$\beta_t=1-t$$. We seek to transform this interpolation into another affine interpolation $$X'_t = \alpha'_t X_1 + \beta'_t X_0.$$ Solving the equations
>
> $$
> \omega_t = \frac{\tau_t}{\alpha'_t} = \frac{1-\tau_t}{\beta'_t}
> $$
>
> yields
>
>$$
> \tau_t = \frac{\alpha'_t}{\alpha'_t + \beta_t'}, \quad \omega_t = \frac{1}{\alpha_t' + \beta_t'}
>$$
>
> Substituting these into the velocity fields, we have
>
> $$
> v'_t(x) = \frac{\dot{\alpha}'_t \beta'_t - \alpha'_t \dot{\beta}'_t}{\alpha'_t + \beta'_t} \cdot v_{\tau_t}(\omega_t x) \;+\; \frac{\dot{\alpha}'_t + \dot{\beta}'_t}{\alpha'_t + \beta'_t} \cdot x.
> $$

### Converting Pretrained RF Velocity

> **Proposition 2**. Assume $$\{X_t\}$$ and $$\{X'_t\}$$ are two affine interpolations:
>
> + Their respective rectified flows $$\{Z_t\}$$ and $$\{Z'_t\}$$ satisfy:
>
> $$
> Z'_t = \omega_t^{-1} Z_{\tau_t}, \quad \forall t \in [0, 1].
> $$
>
> + Their rectified couplings are equivalent:
>
> $$
> (Z_0, Z_1) = (Z'_0, Z'_1).
> $$
>
> + Their RF velocity fields $$v_t$$ and $$v'_t$$ satisfy:
>
> $$
> v'_t(x) = \frac{1}{\omega_t} \left( \dot{\tau}_t v_{\tau_t}(\omega_t x) - \dot{\omega}_t x \right). \tag{3}
> $$

<div class="l-body-outset">
  <iframe src="{{ '/assets/plotly/interp_convert_200step.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

In the figure above, we start with a pretrained RF model that uses a straight interpolation and convert it into a spherical RF. We then apply Euler sampling to both RFs. Although the two RFs follow entirely different trajectories, they both reach the same endpoint $$Z_1$$.

<div class="l-body-outset">
  <iframe src="{{ '/assets/plotly/interp_convert_10step.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

However, as the number of sampling steps decreases to as few as $$10$$, the endpoints $$Z_1$$ and $$Z_1'$$ begin to diverge,  the diffences between them becomes more pronounced with fewer steps. This indicates that, although different affine interpolation schemes theoretically produce the same rectified coupling $$(Z_0, Z_1)$$, their intermediate trajectories $$\{Z_t\}$$ are not the same. When solving the ODEs, discretization errors accumulate along these trajectories. **Straighter trajectories are generally preferable** because they tend to reduce discretization errors and yield more accurate results. 

Owing to the transformation relationships described above, it is possible to change the interpolation scheme of a pretrained model without retraining. This approach allows one to select a scheme that produces straighter trajectories $$\{Z_t\}$$, thus improving the performance of sampling.

## Implications on Loss Functions

Assume that we have trained a model $$\hat{v}_t$$ for the RF velocity field $$v_t$$ under an affine interpolation. Using the formulas from the previous section, we can convert it to a model $$\hat{v}'_t$$ for $$v'_t$$ corresponding to a different interpolation scheme at the post-training stage. This raises the question of what properties the converted model $$\hat{v}'_t$$ may have compared to the models trained directly on the same interpolation, and whether it suffers from performance degradation due to the conversion.

We show here that using different affine interpolation schemes during training is equivalent to applying **different time-weighting** in the loss function, as well as an affine transform on the parametric model. Unless $$\omega_t$$ and $$\tau_t$$ are highly singular, the conversion does not necessarily degrade performance.

Specifically, assume we have trained a parametric model $$v_t(x; \theta)$$ to approximate the RF velocity $$v_t$$ of interpolation $$X_t = \alpha_t X_1 + \beta_t X_0$$, using the mean square loss:

$$
\mathcal L(\theta) = \int_0^1 \mathbb E\left[
\eta_t \left \| \dot X_t - v_t(X_t;\theta)\right\|^2
\right] \mathrm dt \tag{4}
$$

After training, we may convert the obtained model $$v_t(x; \theta)$$ to an approximation of $$v'_t$$ of a different interpolation $$X'_t = \alpha_t' X_1 + \beta_t' X_0$$ via:

$$
v'_t(x; \theta) = \frac{\dot{\tau}_t}{\omega_t} v_{\tau_t}(\omega_t x; \theta) - \frac{\dot{\omega}_t}{\omega_t} x,
$$

On the other hand, if we train $$v'_t(x; \theta)$$ directly to approximate $$v'_t$$ of interpolation $$X'_t = \alpha'_t X_1 + \beta'_t X_0$$, the loss function is:

$$
\mathcal L'(\theta) = \int_0^1 \mathbb{E} \left[ \eta'_t \left\| \dot{X}'_t - v'_t(X'_t; \theta) \right\|^2 \right] \mathrm dt \tag{5}
$$

When matching the loss $$(4)$$ and $$(5)$$, we find that these two training schemes are identical, except for the following time-weighting and reparametrization relationship:

$$
\eta'_t = \frac{\omega_t^2}{\dot{\tau}_t} \eta_{\tau_t},
\quad
v'_t(x; \theta) = \frac{\dot{\tau}_t}{\omega_t} v_{\tau_t}(\omega_t x; \theta) - \frac{\dot{\omega}_t}{\omega_t} x. \tag{6}
$$

In other words, **training with different interpolation schemes simply only introduces different training time weights and model parameterizations.**

> **Example 2. Loss from Straight to Affine** 
>
> Consider the straight interpolation $$X_t = t X_1 + (1 - t) X_0$$ with $$\alpha_t = t$$ and $$\beta_t = 1 - t$$, alongside another affine interpolation $$X_t' = \alpha_t' X_1 + \beta_t' X_0$$.
>
> Suppose we have trained the $$v_t$$ for $$X_t$$ with a time weight $$\eta_t$$, then $$v_t'$$ converted from $$v_t$$ is equivalent to the RF trained with the parametrization in $$(6)$$, and another time weight:
>
> $$
> \eta_t' = \frac{\omega_t^2}{\tau_t'} \eta_{\tau_t} = \frac{1}{\dot{\alpha}_t' \beta_t' - \alpha_t' \dot{\beta}_t'} \eta_{\tau_t},
> $$
>
> Here, we substitute the relationships derived in Example 1 into $$(6)$$.
>

### Straight vs Spherical: Same Train Time Weight

Consider the straight interpolation $$X_t = tX_1 + (1 - t)X_0$$ and an affine interpolation $$X_t' = \alpha_t' X_1 + \beta_t' X_0$$. If

$$
\dot \alpha_t' \beta_t' - \alpha_t \beta_t' = \text{const},
$$

then we have $$\eta_t' \propto \eta_{\tau_t}$$, meaning that the training time weighting remains constant scale across the time.

For example, spherical interpolation satisfies these conditions:

> **Example 3.** Losses for Straight vs. Spherical Interpolation
>
> Consider the spherical interpolation $$X'_t = \sin\left(\frac{\pi t}{2}\right)X_1 + \cos\left(\frac{\pi t}{2}\right)X_0$$, we have
>
> $$
> \eta'_t = \frac{2}{\pi} \eta_{\tau_t},
> \quad
> \tau_t = \frac{\tan\left(\frac{\pi t}{2}\right)}{\tan\left(\frac{\pi t}{2}\right)+1}.
> $$
>
> In this case, training $$v_t$$ with the straight interpolation using a uniform weight $$\eta_t = 1$$ is equivalent to training $$v'_t$$ with the spherical interpolation, also with a uniform weight $$\eta'_t = 2 /\pi$$. The sole difference is a reparameterization of the model:
>
> $$
> v'_t(x, \theta) = \frac{\pi \omega_t}{2} \left( v_{\tau_t}(\omega_t x; \theta) + \left( \cos\left(\frac{\pi t}{2}\right) - \sin\left(\frac{\pi t}{2}\right) \right) x \right),
> $$
>
> where $$\omega_t = (\sin(\frac{\pi t}{2}) + \cos(\frac{\pi t}{2}))^{-1}$$ is bounded within $$[1/\sqrt{2}, 1]$$. This reparameterization does not significantly influence performance. As we'll see in practice, choosing between straight or spherical interpolation makes **little difference** in training outcomes.

<div class="l-body-outset">
  <iframe src="{{ '/assets/plotly/interp_convert_double_rf.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

In the figure above, we compare two RF models: one trained with straight interpolation and another with spherical interpolation. We then convert the straight RF into the spherical one. As Example 3 suggests, we can see that the two trajectories are nearly identical, except for minor divergence near $$t=1$$ due to accumulated numerical errors. 

<div class="l-body-outset">
  <iframe src="{{ '/assets/plotly/interp_match_time_weight.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

In this figure, we reparameterize the straight RF into $$v'_t$$ and train it with spherical interpolation. This time, we find that the resulting trajectories align almost perfectl, since the weight and parametrization match exactly.
