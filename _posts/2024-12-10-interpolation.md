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

Given an arbitrary coupling $$(X_0, X_1)$$ of source distribution $$X_0\sim \pi_0$$ and target unknown data distribution $$X_1 \sim \pi_1$$, recall that rectified flow learns a ODE

$$
\mathrm d Z_t = v_t(Z_t) \mathrm d t,
$$

which, starts from the noise $$Z_0=X_0$$, leads to generated data $$Z_1$$. This velocity is learned by minimizing the mean square loss from the slope of an interpolation process:

$$
\min_v \int _0 ^1 \mathbb E \left[\left\| \dot X_t - v_t(X_t)\right\|^2 
\right] \mathrm d t,
$$

where $$\{X_t\} = \{X_t: t\in [0,1]\}$$ is an interpolation process connecting $$X_0$$ and $$X_1$$, and $$\dot X_t$$ denotes its time derivative. Theoretically, $$\{X_t\}$$ can be any smooth interpolation between source and target distributions. Different methods employ these or other interpolation schemes. 

One might suspect that, since these choices influence the learned rectified flow velocity and thus potentially affect inference performance and speed, they must be decided upon during training. But is this really necessary?

In this blog, we show that if two interpolation processes are *pointwise transformable* in a suitable sense, then they would induce essentially ***equivalent*** rectified flow dynamics and identical couplings. 

Furthermore, as all affine interpolations are pointwise transformable into one another, it suffices to adopt a simple interpolation—such as the straight-line interpolation $$X_t = t X_1 + (1 - t) X_0$$—during training. Later, through simple transformations, any desired affine interpolation can be recovered at the sampling stage. Because of this flexibility, *the choice of interpolation at training time is less critical*, and different interpolation schemes can be freely adopted at inference, where their differences become more relevant.

## Point-wisely Transformable Interpolations

Let us start with a general notion of pointwise transformability between interpolation processes. 

> **Definition 1.** Consider any two interpolation processes $$\{X_t : t \in [0,1]\}$$ and $$\{X'_t : t \in [0,1]\}$$. We say they are **pointwise transformable** if there exist differentiable maps $$\tau: [0,1] \to [0,1]$$ and $$\phi: [0,1] \times \mathbb{R}^d \to \mathbb{R}^d$$ such that $$\phi_t$$ is invertible for every $$t \in [0,1]$$ and 
> 
> $$
> X'_t = \phi_t(X_{\tau_t}) \quad \text{for all } t \in [0,1].
> $$
{: .definition}

If two interpolations are pointwise transformable, then the trajectories of their respective rectified flows satisfy the very same transform. In addition, if the two interpolations are constructed from the same coupling, they yields the same recitifed coupling theoretically. 


> **Theorem 1.** Suppose two interpolations $$\{X_t\}$$ and $$\{X'_t\}$$ are pointwise transformable and constructed from the same coupling $$(X_0, X_1) = (X'_0, X'_1)$$. Assume $$\tau_0=0$$ and $$\tau_1=1$$. 
>
> Let $$\{v_t\}$$ and $$\{v'_t\}$$ be their corresponding rectified flow velocity fields, and $$\{Z_t\}$$ and $$\{Z'_t\}$$ their rectified flows with $$\mathrm d Z_t = v_t(Z_t)\mathrm d t$$, $$Z_0 = X_0$$, and $$\mathrm d Z'_t = v'_t(Z'_t)\mathrm d t$$, $$Z'_0=X'_0$$, respectively. Then
> 
> 1. The rectified flows $$\{Z_t\}\to\{Z'_t\}$$ can be transformed with the very same  pointwise maps:
> 
>    $$
>    Z'_t = \phi_t(Z_{\tau_t}) \quad \text{for all } t \in [0,1].
>    $$
>
> 3. The two rectified flows produce the rectified coupling:
> 
>    $$
>    (Z_0, Z_1) = (Z'_0, Z'_1).
>    $$
>
> 4. Their velocity fields are related by:
> 
>    $$
>    v'_t(x) = \partial_t \phi_t(\phi_t^{-1}(x)) + \bigl(\nabla \phi_t(\phi_t^{-1}(x))\bigr)^\top v_{\tau_t}(\phi_t^{-1}(x)) \dot{\tau}_t. \tag{1}
>    $$
{: .theorem}

In other words, denote by $$\{X'_t\} := \texttt{Transform}(\{X_t\})$$ a pointwise transformation on the interpolations. Then the result shows that the operation $$\texttt{Rectify}(\cdot)$$, which maps an interpolation $$\{X_t\}$$ to its corresponding rectified flow $$\{Z_t\}$$, is **equivariant** under pointwise transformations:

$$
\texttt{Rectify}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{Rectify}(\{X_t\})).
$$

###  Affine Interpolations are Pointwise Transformable

In practice, one often considers interpolations of the form

$$
X_t = \alpha_t X_1 + \beta_t X_0,
$$

where $$\alpha_t$$ and $$\beta_t$$ are monotonic on $$t\in[0,1]$$ and satisfy the boundary conditions:

$$
\alpha_0=\beta_1=0, \quad \alpha_1 = \beta_0 = 1.
$$

All such interpolations are *affine*. Here are some examples of affine interpolations.

1. ***Straight interpolation***, as used in <d-cite key="liu2022flow,lipman2022flow,albergo2023stochastic"></d-cite>:

   $$
   X_t = tX_1 + (1-t) X_0.
   $$

   This yields straight lines connecting $$\pi_0$$ and $$\pi_1$$ at a constant speed $$\dot X_t = X_1 - X_0.$$

2. ***Spherical linear interpolation***  (*slerp*), employed by iDDPM <d-cite key="nichol2021improved"></d-cite>: 

   $$
   X_t = \sin\left(\frac{\pi}{2} t\right)X_1  +   \cos\left(\frac{\pi}{2} t\right)X_0,
   $$

   which travels along the shortest great-circle arc on a sphere at a constant speed.

3. ***DDIM interpolation***,<d-cite key="song2020denoising"></d-cite> a spherical interpolation satisfying $$\alpha_t^2 + \beta_t^2 = 1$$ but with a non-uniform speed defined by $\alpha_t$:

   $$
   X_t = \alpha_t X_1 + \sqrt{1-\alpha_t^2} X_0,
   $$

   where $$\alpha_t = \exp\bigl(-\frac{1}{4}a(1-t)^2 - \tfrac{1}{2}b(1-t)\bigr)$$, and $$a=19.9,b=0.1$$ by default.

For this class of interpolations, the maps $$\phi$$ and $$\tau$$ reduce to scalar transforms. **All affine interpolations are pointwise transformable** by appropriately scaling  time and input. Consequently, their corresponding rectified flows can also be related through the same pointwise transforms, ultimately producing the same rectified couplings. This result aligns with observations made by other authors<d-cite key="karras2022elucidating,kingma2024understanding,shaulbespoke,gao2025diffusionmeetsflow"></d-cite>. 

> **Proposition 1.** Consider two **affine interpolation** processes derived from the same coupling $$(X_0, X_1)$$:
> 
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
> The solution of $$(\tau_t, \omega_t)$$  exists and is unique if  $$\alpha'_t/\beta'_t \geq 0$$ and $$\alpha_t/\beta_t$$ is continuous and strictly increasing for $$t \in [0,1]$$. 
{: .definition}

In practice, the equation regarding $$\tau_t$$ can be solved with a [simple binary search](https://github.com/lqiang67/rectified-flow/blob/main/rectified_flow/flow_components/interpolation_convertor.py). 
In some simple cases, the solution can be derived  analytically. 

The figure below illustrates the $$\tau$$ and $$\phi$$ transformations that convert DDIM to spherical interpolation, and straight interpolation to spherical. Note that when converting DDIM to spherical interpolation, the only difference is in the time scaling—$$\omega_t$$ remains constant at $$1$$.

<div class="l-body-outset">
  <figure id="figure-1">
    <div style="display: flex;">
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
    <figcaption>
      <a href="#figure-1">Figure 1</a>.
      The figure illustrates the \(\tau\) and \(\phi\) transformations that convert DDIM to spherical interpolation(left), and straight interpolation to spherical(right). Note that when converting DDIM to spherical interpolation, the only difference is in the time scaling—\(\omega_t\) remains constant at \(1\).
    </figcaption>
  </figure>
</div>

Combining Proposition 1 with Theorem 1, we have: 

> **Proposition 2**. Assume $$\{X_t\}$$ and $$\{X'_t\}$$ are two **affine interpolations**:
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
{: .definition}


> **Example 1.** Converting **straight** interpolation into **affine** ones.
>
> Consider the straight interpolation $$X_t=tX_1 + (1-t)X_0$$ with $$\alpha_t=t$$ and $$\beta_t=1-t$$. We seek to transform it into another affine interpolation $$X'_t = \alpha'_t X_1 + \beta'_t X_0.$$ Solving the equations
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
> v'_t(x) = \frac{\dot{\alpha}'_t \beta'_t - \alpha'_t \dot{\beta}'_t}{\alpha'_t + \beta'_t}  v_{\tau_t}(\omega_t x) \;+\; \frac{\dot{\alpha}'_t + \dot{\beta}'_t}{\alpha'_t + \beta'_t}  x.
> $$
{: .example}


<div class="l-body-outset">
  <figure id="figure-2">
    <iframe src="{{ '/assets/plotly/interp_convert_200step.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-2">Figure 2</a>.
      Starting from a pretrained straight rectified flow, we convert it into a spherical rf and then apply Euler sampling to both. 
      Although the two rfs follow entirely different trajectories, they both converge to the same endpoint \(Z_1\), resulting in the same rectified coupling.
    </figcaption>
  </figure>
</div>

<div class="l-body-outset">
  <figure id="figure-3">
    <iframe src="{{ '/assets/plotly/interp_convert_10step.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-3">Figure 3</a>.
      As the number of sampling steps decreases to as few as \(10\), the endpoints \(Z_1\) and \(Z_1'\) begin to diverge, and the differences between them become more pronounced with fewer steps.
      Although different affine interpolation schemes yield the same rectified coupling \((Z_0, Z_1)\) in theory, their trajectories \(\{Z_t\}\) differ in practice. 
      When solving ODEs numerically, discretization errors accumulate along the trajectory. 
      Straighter trajectories are generally preferable because they reduce these errors and improve the accuracy of the final results.
    </figcaption>
  </figure>
</div>

Thanks to the transformation relationships described above, it is possible to change the interpolation scheme of a pretrained model without retraining. This approach allows one to select a scheme that produces straighter trajectories $$\{Z_t\}$$, thus improving the sampling performance.

## Implications on Loss Functions

Assume that we have trained a paramtric model $$v_t(x;\theta)$$ for the RF velocity field $$v_t(x)$$ under an affine interpolation. Using the formulas from the previous section, we can convert it to a model $$v'_t(x, \theta)$$ for $$v'_t(x)$$ corresponding to a different interpolation scheme at the post-training stage. 

This raises the question of what properties the converted model $$\hat{v}'_t$$ may have compared to the models trained directly on the same interpolation, and whether it suffers from performance degradation due to the conversion.

It turns out that using different affine interpolation schemes during training is equivalent to applying **different time-weighting** in the loss function, as well as an affine transform on the parametric model. Unless $$\omega_t$$ and $$\tau_t$$ are highly singular, the conversion does not necessarily degrade performance.

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

By matching the loss $$(4)$$ and $$(5)$$, derivations show  that these two training schemes are identical, except for the following time-weighting and reparametrization relationship:

$$
\eta'_t = \frac{\omega_t^2}{\dot{\tau}_t} \eta_{\tau_t},
\quad
v'_t(x; \theta) = \frac{\dot{\tau}_t}{\omega_t} v_{\tau_t}(\omega_t x; \theta) - \frac{\dot{\omega}_t}{\omega_t} x. \tag{6}
$$

In other words, **training with different interpolation schemes simply only introduces different training time weights and model parameterizations.**

> **Example 2. Loss from Straight to Affine**  
> Consider the straight interpolation $$X_t = t X_1 + (1 - t) X_0$$ with $$\alpha_t = t$$ and $$\beta_t = 1 - t$$, alongside another affine interpolation $$X_t' = \alpha_t' X_1 + \beta_t' X_0.$$
>
> Suppose we have trained the $$v_t$$ for $$X_t$$ with a time weight $$\eta_t$$, then $$v_t'$$ converted from $$v_t$$ is equivalent to the RF trained with the parametrization in $$(6)$$, and another time weight:
>
> $$
> \eta_t' = \frac{\omega_t^2}{\tau_t'} \eta_{\tau_t} = \frac{1}{\dot{\alpha}_t' \beta_t' - \alpha_t' \dot{\beta}_t'} \eta_{\tau_t},
> $$
>
> Here, we substitute the relationships derived in Example 1 into $$(6)$$.
>
{: .example}

### Straight vs Spherical: Same Train Time Weight


> **Example 3. Losses for Straight vs. Spherical Interpolation**
> 
> Following Example 2, an interesting case is when 
$$
\dot \alpha_t' \beta_t' - \alpha_t \beta_t' = \text{const},
$$
> with which  we have $$\eta_t' \propto \eta_{\tau_t}$$. Moreover, if $\eta_t = 1$ is uniform, then $\eta_t'$ is also uniform,  meaning that the two interpolations share the same loss function.  
> 
> This happens to the spherical interpolation $$X'_t = \sin\left(\frac{\pi t}{2}\right)X_1 + \cos\left(\frac{\pi t}{2}\right)X_0,$$ for which we have $$\dot \alpha_t' \beta_t' - \alpha_t \beta_t'  = \frac{\pi}{2}$$ and hence 
>
> $$
> \eta'_t = \frac{2}{\pi} \eta_{\tau_t},
> \quad
> \tau_t = \frac{\tan\left(\frac{\pi }{2} t \right)}{\tan\left(\frac{\pi }{2}t\right)+1}.
> $$
>
> In this case, training $$v_t$$ with the straight interpolation using a uniform weight $$\eta_t = 1$$ is equivalent to training $$v'_t$$ with the spherical interpolation, also with a uniform weight $$\eta'_t = 2 /\pi$$. The sole difference is a reparameterization of the model:
>
> $$
> v'_t(x, \theta) = \frac{\pi \omega_t}{2} \left( v_{\tau_t}(\omega_t x; \theta) + \left( \cos\left(\frac{\pi t}{2}\right) - \sin\left(\frac{\pi t}{2}\right) \right) x \right),
> $$
>
> where $$\omega_t = (\sin(\frac{\pi t}{2}) + \cos(\frac{\pi t}{2}))^{-1}$$ is bounded within $$[1/\sqrt{2}, 1]$$. This reparameterization does not significantly influence performance. As we'll see in practice, choosing between straight or spherical interpolation makes **little difference** in training outcomes.
{: .example}

<div class="l-body-outset">
  <figure id="figure-4">
    <iframe src="{{ '/assets/plotly/interp_convert_double_rf.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-4">Figure 4</a>.
      Comparing two rf models, one trained with straight interpolation and another with spherical interpolation, 
      we then convert the straight rf into the spherical one. As seen in Example 3, the two trajectories are nearly identical, 
      differing slightly at the end due to accumulated numerical errors.
    </figcaption>
  </figure>
</div>

<div class="l-body-outset">
  <figure id="figure-5">
    <iframe src="{{ '/assets/plotly/interp_match_time_weight.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-5">Figure 5</a>.
      Here we reparameterize the straight RF into \(v'_t\) and train it using spherical interpolation. 
      Under these matched conditions (both weighting and parameterization), the resulting trajectories align almost perfectly.
    </figcaption>
  </figure>
</div>