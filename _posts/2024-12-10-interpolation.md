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


bibliography: reference.bib


toc:
  - name: "Overview"
  - name: "Point-wisely Transformable Interpolations"
    subsections:
      - name: "Affine Interpolations are Pointwise Transformable"
  - name: "Implications on Loss Functions"
    subsections:
      - name: "Straight vs Spherical: Identical Train Time Weight"
---

<!-- 
<div class="hero">
  <img src="/assets/img/teaser_post2.png" alt="Rectified Flow Overview" style="width: 100%; max-height: 500px; object-fit: cover; border-radius: 10px; margin-bottom: 20px;">
</div>
--> 

This blog introduces the equivalent relationships between rectified flows induced from different affine interpolations, based on Chapter 3 of these [lecture notes](https://github.com/lqiang67/rectified-flow/tree/main/pdf).  Related observations and discussion can also be found in <d-cite key="karras2022elucidating,kingma2024understanding,shaulbespoke,gao2025diffusionmeetsflow"></d-cite>.

## Overview

Given a coupling $$(X_0, X_1)$$ of source distribution $$X_0\sim \pi_0$$ and target unknown data distribution $$X_1 \sim \pi_1$$, recall that rectified flow learns an ODE

$$
\mathrm d Z_t = v_t(Z_t) \, \mathrm d t,
$$

which, starts from the noise $$Z_0=X_0$$, ends at generated data $$Z_1$$. This velocity field $$v_t$$ is learned by minimizing the mean square error from the slope of an interpolation process:

$$
\min_v \int _0 ^1 \mathbb E \left[\left\| \dot X_t - v_t(X_t)\right\|^2 
\right] \mathrm d t,
$$

where $$\{X_t\} = \{X_t: t\in [0,1]\}$$ is the interpolation process connecting $$X_0$$ and $$X_1$$, and $$\dot X_t$$ denotes its time derivative. We call the ODE process $$\mathrm d Z_t = v_t(Z_t) \mathrm d t$$ with $$Z_0=X_0$$ the rectified flow induced from $$\{X_t\}$$, and denote it as:

$$
\{Z_t\} = \texttt {Rectify}(\{X_t\}).
$$

In principle, any smooth interpolation $$\{X_t\}$$ connecting $$X_0$$ and $$X_1$$ can be used. Different methods employ these or other interpolation schemes. One might suspect that, since these choices influence the learned rectified flow and thus potentially affect inference performance and speed, they must be decided upon during training. But is this really necessary?

In this blog, we show that if two interpolation processes are *pointwise transformable* in a suitable sense, then they would induce ***equivalent*** rectified flow dynamics and identical couplings. In particular, any two affine interpolations are pointwise transformable. Consequently, it suffices to train with a simple scheme—such as the straight-line interpolation $$X_t = t X_1 + (1 - t) X_0$$—and then convert to another affine interpolation at inference. This flexibility implies that the training-time interpolation choice is not critical; one can defer such decisions to inference.

## Point-wisely Transformable Interpolations

We first define what we mean by pointwise transformability.

> **Definition 1.** Let $$\{X_t : t \in [0,1]\}$$ and $$\{X'_t : t \in [0,1]\}$$ be two interpolations. They are **pointwise transformable** if there exist differentiable maps $$\tau: [0,1] \to [0,1]$$ and $$\phi: [0,1] \times \mathbb{R}^d \to \mathbb{R}^d$$ such that $$\phi_t$$ is invertible for each $$t \in [0,1],$$ and 
> 
> $$
> X'_t = \phi_t(X_{\tau_t}), \quad  \forall t \in [0,1].
> $$
{: .definition}

If two interpolations are pointwise transformable and contructed from the same coupling, their rectified flows are also related by the **same** transform, and they induce the same coupling.


> **Theorem 1.** Suppose $$\{X_t\}$$ and $$\{X'_t\}$$ are pointwise transformable and constructed from the same coupling $$(X_0, X_1) = (X'_0, X'_1)$$. Assume $$\tau_0=0$$ and $$\tau_1=1$$. 
>
> Let $$\{v_t\}$$ and $$\{v'_t\}$$ be the corresponding rectified flow velocity fields, and let $$\{Z_t\}$$ and $$\{Z'_t\}$$ their rectified flows with $$\mathrm d Z_t = v_t(Z_t)\mathrm d t,Z_0 = X_0$$ and $$\mathrm d Z'_t = v'_t(Z'_t)\mathrm d t, Z'_0=X'_0.$$ Then:
> 
> 1. $$\{Z_t\},\{Z'_t\}$$ can be transformed with the same pointwise maps:
> 
>    $$
>    Z'_t = \phi_t(Z_{\tau_t}) \quad \text{for all } t \in [0,1].
>    $$
>
> 3. The rectified couplings match:
> 
>    $$
>    (Z_0, Z_1) = (Z'_0, Z'_1).
>    $$
>
> 4. The velocity fields satisfy:
> 
>    $$
>    v'_t(x) = \partial_t \phi_t(\phi_t^{-1}(x)) + \bigl(\nabla \phi_t(\phi_t^{-1}(x))\bigr)^\top v_{\tau_t}(\phi_t^{-1}(x)) \dot{\tau}_t. \tag{1}
>    $$
{: .theorem}

Thus, for a pointwise transform $$\texttt{Transform},$$

$$
\texttt{Rectify}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{Rectify}(\{X_t\})).
$$

###  Affine Interpolations are Pointwise Transformable

Many commonly used interpolation schemes are affine, they can be expressed as:

$$
X_t = \alpha_t X_1 + \beta_t X_0,
$$

with $$\alpha_t$$ and $$\beta_t$$ are monotone, $$\alpha_0=\beta_1=0,$$ and $$\alpha_1 = \beta_0 = 1.$$

Some examples of affine interpolations:

1. ***Straight interpolation*** <d-cite key="liu2022flow,lipman2022flow,albergo2023stochastic"></d-cite>:

   $$
   X_t = tX_1 + (1-t) X_0.
   $$
   
   This yields straight lines connecting $$\pi_0$$ and $$\pi_1$$ at a constant speed $$\dot X_t = X_1 - X_0.$$
   
2. ***Spherical linear interpolation***  (*slerp*) <d-cite key="nichol2021improved"></d-cite>: 

   $$
   X_t = \sin\left(\frac{\pi}{2} t\right)X_1  +   \cos\left(\frac{\pi}{2} t\right)X_0,
   $$
   
   which travels along the shortest great-circle arc on a sphere at a constant speed.
   
3. ***DDIM interpolation*** <d-cite key="song2020denoising"></d-cite> a spherical interpolation satisfying $$\alpha_t^2 + \beta_t^2 = 1$$ but with a non-uniform speed defined by $\alpha_t$:

   $$
   X_t = \alpha_t X_1 + \sqrt{1-\alpha_t^2} X_0,
   $$
   

where $$\alpha_t = \exp\bigl(-\frac{1}{4}a(1-t)^2 - \tfrac{1}{2}b(1-t)\bigr)$$, and $$a=19.9,b=0.1$$ by default.

For affine interpolations, the maps $$\phi$$ and $$\tau$$ reduce to scalar transforms: **All affine interpolations are pointwise transformable by adjusting time and scaling**. Hence, their induced rectified flows and couplings are equivalent. This result aligns with observations made by other authors<d-cite key="karras2022elucidating,kingma2024understanding,shaulbespoke,gao2025diffusionmeetsflow"></d-cite>. 

> **Proposition 1. Conversion of Affine Interpolations**
>
> Let $$X_t = \alpha_t X_1 + \beta_t X_0$$ and $$X_t' = \alpha_t' X_1 + \beta_t' X_0$$ be two affine interpolations from the same coupling $$(X_0, X_1).$$ Then there exist scalar functions $$\tau_t$$ and $$\omega_t$$ such that
> $$
> X_t' = \frac{1}{\omega_t} X_{\tau_t}, \quad \forall t \in [0,1],
> $$
>
> where $$\tau_t$$ and $$\omega_t$$ solve
>
> $$
> \frac{\alpha_{\tau_t}}{\beta_{\tau_t}} = \frac{\alpha'_t}{\beta'_t}, \quad \omega_t = \frac{\alpha_{\tau_t}}{\alpha'_t} = \frac{\beta_{\tau_t}}{\beta'_t}, \quad \forall t \in (0, 1) \tag{2}
> $$
>
> with the boundary conditions $$\omega_0 = \omega_1 = 1,  \tau_0 = 0,  \tau_1 = 1.$$
{: .definition}

In practice, we can determine $$\tau_t$$ numerically—e.g., via a [binary search](https://github.com/lqiang67/rectified-flow/blob/main/rectified_flow/flow_components/interpolation_convertor.py)—or derive an analytic solution in certain simple cases.

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
      This figure shows the \(\tau\) and \(\omega\) transformations used to convert DDIM to spherical interpolation (left) and to convert straight interpolation to spherical (right). When converting DDIM to spherical, only the time scaling changes, as \(\omega_t\) remains fixed at 1.
    </figcaption>
  </figure>
</div>


Combining Proposition 1 with Theorem 1, we have: 

> **Proposition 2. Rectified Flows between Affine Interpolation**
>
> For affine interpolations $$\{X_t\}$$ and $$\{X'_t\}$$:
>
> + Their rectified flows $$\{Z_t\}$$ and $$\{Z'_t\}$$ satisfy:
>
> $$
> Z'_t = \frac 1 {\omega_t} Z_{\tau_t}, \quad \forall t \in [0, 1].
> $$
>
> + Their rectified couplings match:
>
> $$
> (Z_0, Z_1) = (Z'_0, Z'_1).
> $$
>
> + Their rectified flow velocity fields $$v_t$$ and $$v'_t$$ relate as:
>
> $$
> v'_t(x) = \frac{1}{\omega_t} \left( \dot{\tau}_t v_{\tau_t}(\omega_t x) - \dot{\omega}_t x \right). \tag{3}
> $$
{: .definition}


> **Example 1. Velocity from Straight  to Affine**
>
> For the straight interpolation $$X_t=tX_1 + (1-t)X_0$$ with $$\alpha_t=t$$ and $$\beta_t=1-t$$. Convert it into another affine interpolation $$X'_t = \alpha'_t X_1 + \beta'_t X_0$$ yields:
>
> $$
> \tau_t = \frac{\alpha'_t}{\alpha'_t + \beta_t'}, \quad \omega_t = \frac{1}{\alpha_t' + \beta_t'}.
> $$
>
> Their rectified flow velocity fields satisfy:
>
>$$
> v'_t(x) = \frac{\dot{\alpha}'_t \beta'_t - \alpha'_t \dot{\beta}'_t}{\alpha'_t + \beta'_t}  v_{\tau_t}(\omega_t x) \;+\; \frac{\dot{\alpha}'_t + \dot{\beta}'_t}{\alpha'_t + \beta'_t}  x.
>$$
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
      Beginning with a rectified flow trained under straight interpolation, we convert it into a spherical rectified flow and apply Euler sampling to both. Although the two rectified flows follow different paths, they converge to the same endpoint \(Z_1\) because their continuous-time ODE trajectories are equivalent.
    </figcaption>
  </figure>
</div>

### Implication on Inference

<div class="l-body-outset">
  <figure id="figure-3">
    <div style="display: flex;">
      <iframe src="{{ 'assets/plotly/interp_convert_10step_straight.html' | relative_url }}" 
              frameborder="0" 
              scrolling="no" 
              height="430px" 
              width="49%"></iframe>
      <iframe src="{{ 'assets/plotly/interp_convert_10step_spherical.html' | relative_url }}" 
              frameborder="0" 
              scrolling="no" 
              height="430px" 
              width="49%"></iframe>
    </div>
    <figcaption>
      <a href="#figure-3">Figure 3</a>.
      As we reduce the number of Euler steps to 4, the generated results become completely different.
    </figcaption>
  </figure>
</div>

<div class="l-body">
  <figure id="figure-4">
    <iframe src="{{ '/assets/plotly/interp_mse_step.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="310px" 
          width="60%">
    </iframe>
    <figcaption>
      <a href="#figure-4">Figure 4</a>.
      The Mean Square Error (MSE) between results generated by the two RFs decreases as the number of inference steps increases, indicating that their continuous ODEs produce the same results. However, different discretization schemes still lead to variations in performance.
    </figcaption>
  </figure>
</div>

In theory, different affine interpolations induce equivalent continuous-time rectified flows. However, when we numerically solve ODEs, different interpolation schemes produce different discretization errors. Straighter trajectories generally yield smaller errors and more accurate final results.

Fortunately, because we can convert between affine interpolation schemes without retraining, we can choose a scheme at inference time that yields "straighter" trajectories $$\{Z_t\}$$, thus improving sampling performance.

## Implications on Loss Functions

Suppose we have trained a parametric model $$v_t(x;\theta)$$ to approximate the RF velocity field $$v_t(x)$$ under a particular affine interpolation. After training, we can use the relationships derived above to convert this model into $$v'_t(x;\theta)$$, corresponding to a different affine interpolation, without retraining.

This leads to two related questions:  

1. How does training with one interpolation differ from training directly with another?  
2. Does converting a pretrained model $$v_t$$ to $$v'_t$$ degrade performance?

It turns out that choosing a different affine interpolation during training is equivalent to changing the **time-weighting** in the loss function and applying an affine transform to the model parameterization. As long as the transformations $$\omega_t$$ and $$\tau_t$$ are not highly singular, converting a model from one affine interpolation to another does not inherently reduce performance.

Specifically, consider a model $$v_t(x; \theta)$$ trained to approximate the RF velocity $$v_t$$ of interpolation $$X_t = \alpha_t X_1 + \beta_t X_0$$:

$$
\mathcal L(\theta) = \int_0^1 \mathbb E\left[
\eta_t \left \| \dot X_t - v_t(X_t;\theta)\right\|^2
\right] \mathrm dt. \tag{4}
$$

After training, we can convert this model $$v_t(x; \theta)$$ into an approximation of $$v'_t$$ of a different interpolation $$X'_t = \alpha_t' X_1 + \beta_t' X_0$$ via:

$$
v'_t(x; \theta) = \frac{\dot{\tau}_t}{\omega_t} v_{\tau_t}(\omega_t x; \theta) - \frac{\dot{\omega}_t}{\omega_t} x.
$$

On the other hand, if we were to train $$v'_t(x; \theta)$$ directly to approximate the velocity $$v'_t$$ of interpolation $$X'_t = \alpha'_t X_1 + \beta'_t X_0$$, the loss function is:

$$
\mathcal L'(\theta) = \int_0^1 \mathbb{E} \left[ \eta'_t \left\| \dot{X}'_t - v'_t(X'_t; \theta) \right\|^2 \right] \mathrm dt \tag{5}
$$

Matching the loss $$(4)$$ and $$(5)$$, shows that the two training schemes differ only in time-weighting and parameterization. Specifically,

$$
\eta'_t = \frac{\omega_t^2}{\dot{\tau}_t} \eta_{\tau_t},
\quad
v'_t(x; \theta) = \frac{\dot{\tau}_t}{\omega_t} v_{\tau_t}(\omega_t x; \theta) - \frac{\dot{\omega}_t}{\omega_t} x. \tag{6}
$$

In other words, **training under different affine interpolation schemes is equivalent to applying a different time-weighting function and a corresponding model reparameterization.**

> **Example 2. Loss from Straight to Affine** 
>
> Consider the straight interpolation $$X_t = t X_1 + (1 - t) X_0$$ and another affine interpolation $$X_t' = \alpha_t' X_1 + \beta_t' X_0.$$
>
> Suppose we have trained a model $$v_t$$ for the straight interpolation with time weights $$\eta_t.$$ Then $$v_t'$$ converted from $$v_t$$ corresponds to the RF trained with the parametrization in $$(6)$$, and a different time-weighting:
>
> $$
> \eta_t' = \frac{\omega_t^2}{\tau_t'} \eta_{\tau_t} = \frac{1}{\dot{\alpha}_t' \beta_t' - \alpha_t' \dot{\beta}_t'} \eta_{\tau_t}.
> $$
>
> Here, we substitute the relationships derived in Example 1 into $$(6)$$.
>
{: .example}

### Straight vs. Spherical: Identical Train Time Weight

Following Example 2, an interesting case arises when $$\dot{\alpha}'_t \beta'_t - \alpha'_t \dot{\beta}'_t$$ is a constant. In this case, $$\eta'_t$$ is proportional to $$\eta_{\tau_t}$$. If $$\eta_t = 1$$ is uniform, then $$\eta'_t$$ also remains uniform, meaning the two interpolation schemes share the same loss function.

> **Example 3. Losses for Straight vs. Spherical Interpolation**
> 
> Consider the spherical interpolation:
> $$
> X'_t = \sin\left(\frac{\pi t}{2}\right)X_1 + \cos\left(\frac{\pi t}{2}\right)X_0.
> $$
>
> For this choice, $$\dot{\alpha}'_t \beta'_t - \alpha'_t \dot{\beta}'_t = \frac{\pi}{2}$$. Hence:
>
> $$
> \eta'_t = \frac{2}{\pi}\eta_{\tau_t}, \quad \tau_t = \frac{\tan\left(\frac{\pi t}{2}\right)}{\tan\left(\frac{\pi t}{2}\right)+1}.
> $$
>
> Thus, training $$v_t$$ for the straight interpolation with a uniform weight ($$\eta_t=1$$) is equivalent to training $$v'_t$$ for the spherical interpolation with a uniform weight ($$\eta'_t=2/\pi$$). The only difference is a reparameterization of the model:
>
> $$
> v'_t(x, \theta) = \frac{\pi \omega_t}{2} \left( v_{\tau_t}(\omega_t x; \theta) + \left( \cos\left(\frac{\pi t}{2}\right) - \sin\left(\frac{\pi t}{2}\right) \right) x \right),
> $$
>
> where $$\omega_t = (\sin(\frac{\pi t}{2}) + \cos(\frac{\pi t}{2}))^{-1}$$ is bounded within $$[1/\sqrt{2}, 1]$$. 
{: .example}

This reparameterization does not significantly affect performance. In the following figures, we show that choosing between straight or spherical interpolation makes **little difference** in training outcomes.

<div class="l-body-outset">
  <figure id="figure-5">
    <iframe src="{{ '/assets/plotly/interp_convert_double_rf.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-5">Figure 5</a>.
      Comparing two RF models: one trained with straight interpolation and another trained with spherical interpolation, both uniform loss weight. We then convert the straight RF into a spherical form ("RF trained from straight"). Since both share the same loss function, the only difference lies in model parameterization. The results show only minor discrepancies, confirming that the reparameterization’s impact on performance is limited.
    </figcaption>
  </figure>
</div>

