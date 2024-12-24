---
layout: distill
title: "Curved × Curved = Straight: DDIM is Straight RF" 
description: The discretized inference scheme of DDIM corresponds to a curved Euler method on curved trajectories, and is equivalent to the vanilla Euler method applied to straight rectified flow. But the later is simpler...
tags: tutorial
giscus_comments: true
date: 2024-12-10 11:00:00
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

thumbnail: /assets/img/thumbnail/natural_euler_thumbnail.png
thumbnail_alt: "Thumbnail of Natural Euler"

authors:
  - name: Runlong Liao
    url: "mailto:rectifiedflow@gmail.com"
    affiliations:
      name: UT Austin
  - name: Xixi Hu
  - name: Bo Liu
  - name: Qiang Liu

# 如果有文献，请指定bibliography文件
bibliography: reference.bib

# 可选的目录配置
toc:
  - name: "Overview"
  - name: "Affine Interpolation Solver"
  - name: "Natural Euler Sampler"
  - name: "Equivalence of Natural Euler Trajectories"

---
<!-- 
<div class="hero">
  <img src="/assets/img/teaser_post4.png" alt="Rectified Flow Overview" style="width: 100%; max-height: 500px; object-fit: cover; border-radius: 10px; margin-bottom: 20px;">
</div>
--> 

## Overview

Rectified flow learns an ODE of the form $$\mathrm{d}Z_t = v_t(Z_t; \theta) \mathrm{d} t$$ by matching its velocity field $$v_t(x)$$ and the expected slope $$\mathbb{E}[\dot X_t |X_t=x]$$ of an interpolation process $$\{X_t\}$$ that connects the noise $$X_0$$ and data $$X_1$$. As discussed in a [previous blog](../interpolation/#affine-interpolations-are-pointwise-transformable), different affine interpolations $$X_t = \alpha_t X_1 + \beta_t X_0$$ yield equivariant rectified flows and the identical noise-data coupling.

In practice, ordinary differential equations (ODEs) must be approximated using **discrete solvers**. A common approach is the Euler method:

$$
\hat{Z}_{t+\epsilon} = \hat{Z}_t + \epsilon v_t(\hat{Z}_t),
$$

where the local trajectory is approximated by a tangent line with a step size of $$\epsilon$$. For rectified flows induced by straight-line interpolation, $$X_t = t X_1 + (1-t)X_0$$, this approach is natural. However, if the interpolation is curved, it may be natural to approximate each step with a curved segment that aligns with the interpolation. 
We refer to this method as **natural Euler samplers**.

For example, in the case of affine interpolations $$X_t = \alpha_t X_1 + \beta_t X_0$$, 
as shown in the sequel, such **natural Euler samplers** can be derived as 

$$
\hat{Z}_{t+\epsilon} = \frac{\dot{\alpha}_t \beta_{t+\epsilon} - \alpha_{t+\epsilon} \dot{\beta}_t}{\dot{\alpha}_t \beta_t - \alpha_t \dot{\beta}_t} \hat{Z}_t + \frac{\alpha_{t+\epsilon} \beta_t - \alpha_t \beta_{t+\epsilon}}{\dot{\alpha}_t \beta_t - \alpha_t \dot{\beta}_t} v_t(\hat{Z}_t).
$$

While this expression looks complex, it simplifies to the standard Euler method when $$\alpha_t = t$$ and $$\beta_t = 1-t$$.  
Furthermore, it reproduces the  inference update rule of DDIM in the case where $$\alpha_t^2 + \beta_t^2 = 1$$, matching Equation 13 in \cite{song2020denoising}. The natural Euler perspective provides simplified understanding and implementation of DDIM. 

<div class="l-body">
  <figure id="figure-svg">
    <object
      data="{{ '/assets/img/natural_euler.svg' | relative_url }}"
      type="image/svg+xml"
      width="100%"
      height="200px"
    >
      <!-- Fallback content for browsers that do not support embedded SVG -->
      <p>
        Your browser does not support embedded SVG.
        <a href="{{ '/assets/img/natural_euler.svg' | relative_url }}">Download here</a>.
      </p>
    </object>
    <figcaption>
      <a href="#figure-natural-euler"></a>
    </figcaption>
  </figure>
</div>

However, we can go one step further to eliminate DDIM completely, as all natural Euler samplers of affine interpolations—being pointwise transformable to one another—are equivalent:

> If two interpolation processes are related by a pointwise transform, then **their discrete trajectories obtained through natural Euler sampling are also related by the same pointwise transform**, provided the time grids are appropriately scaled.
{: .definition}

In other words, **when using natural Euler samplers, switching the affine interpolation scheme *at inference time* is essentially adjusting the sampling time grid.** For DDIM, we obtain **exactly the same discrete samples** as those produced by a standard Euler solver applied to the rectified flow induced by straight interpolation, once we properly rescale the time grid.

For a more in-depth discussion on this topic, please refer to Chapter 5 in the [Rectified Flow Lecture Notes](https://github.com/lqiang67/rectified-flow/tree/main/pdf).

## Affine Interpolation Solver

Consider a coupling $$(X_0, X_1)$$ of source distirbution $$X_0 \sim \pi_0$$ and target unknown data distribution $$X_1 \sim \pi_1$$. Define an interpolation function: $$\mathtt I:[0,1] \times \mathbb R^d \times \mathbb R^d \mapsto \mathbb R^d$$ such that 

$$
\mathtt I_0(X_0, X_1) = X_0, \quad \mathtt I_1(X_0, X_1)=X_1.
$$

We assume $$\mathtt I_t$$ is differentiable in $$t$$, and denote

$$
X_t = \mathtt I_t(X_0, X_1), \quad \dot{X}_t = \partial_t \mathtt{I}_t(X_0, X_1).
$$

In many cases, given sample and velocity $$(X_t, \dot{X}_t)$$, we want to recover $$(X_0, X_1)$$ that satisfy  

$$
\begin{cases}
X_t = \mathtt{I}_t(X_0, X_1), \\[6pt]
\dot{X}_t = \partial_t \mathtt{I}_t(X_0, X_1).
\end{cases}
$$

For affine interpolations $$X_t = \alpha_t X_1 + \beta_t X_0$$, this problem reduces to solving a simple $$2 \times 2$$ linear system. Moreover, due to the linearity of expectations, the following conditional expectations also inherit this linear structure.

> **Affine Interpolation Solvers.**  
>
> Define
> 
> $$
> \begin{aligned}
> v_t(x) &:= \mathbb{E}[\dot{X}_t \mid X_t = x], &\text{(RF velocity field)} \\[6pt]
> \hat{x}_{0\mid t}(x) &:= \mathbb{E}[X_0 \mid X_t = x], &\text{(Expected noise $X_0$)} \\[6pt]
> \hat{x}_{1\mid t}(x) &:= \mathbb{E}[X_1 \mid X_t = x]. &\text{(Expected data $X_1$)}
> \end{aligned}
> $$
>
> Given any two of $$\{\dot X_t, X_0, X_1, X_t\}$$ (from interpolation) or $$\{v_t, \hat x_{0\mid t}, \hat x_{1\mid t}, x_t\}$$ (from rectified flow), we can solve explicitly for the other two that satisfy
>
> $$
> X_t = \alpha_t X_1 + \beta_t X_0, \quad \dot{X}_t = \dot{\alpha}_t X_1 + \dot{\beta}_t X_0. \\
> $$
>
> or
>
> $$
> x_t =\alpha_t\hat{x}_{1\mid t} + \beta_t \hat{x}_{0\mid t}, \quad v_t = \dot \alpha_t \hat{x}_{1\mid t} + \dot \beta_t \hat{x}_{0\mid t}
> $$
>
> This can be efficiently implemented as [affine interpolation solvers](https://github.com/lqiang67/rectified-flow/blob/main/rectified_flow/flow_components/interpolation_solver.py).
{: .example}

## Natural Euler Sampler

The standard Euler method approximates the flow $$\{Z_t\}$$ on a discrete time grid $$\{t_i\}$$ by using  locally linear steps:

$$
\hat{z}_{t_{i+1}} = \hat{z}_{t_i} + (t_{i+1} - t_i) \cdot v_{t_i}(\hat{z}_{t_i}).
$$

This treats the local trajectory as a straight line tangent at $$\hat{z}_{t_i}$$.

In contrast, the **natural Euler sampler** uses the interpolation curve that is tangent at $$\hat{z}_{t_i}$$. Instead of advancing along a straight line, it follows a locally curved trajectory consistent with the given interpolation scheme. The update rule is:

$$
\hat{z}_{t_{i+1}} = \mathtt{I}_{t_{i+1}}(\hat{x}_{0 \mid t_i}, \hat{x}_{1 \mid t_i}),
$$

where $$\hat{x}_{0 \mid t_i}$$ and $$\hat{x}_{1 \mid t_i}$$ are determined by identifying the interpolation curve that passes through $$\hat{z}_{t_i}$$ and satisfies $$\partial \mathtt{I}_{t_i}(\hat{x}_{0 \mid t_i}, \hat{x}_{1 \mid t_i}) = v_{t_i}(\hat{z}_{t_i}).$$ In other words, we first find the specific interpolation curve $$\mathtt{I}$$ that matches the given slope at $$\hat{z}_{t_i}$$, then advance one step along it.

For instance, the natural euler sampler under spherical RF is


> **Example 1. Natural Euler Sampler for Spherical Interpolation**
> 
>$$
>\hat z_{t + \epsilon} =\cos\left(\frac{\pi}{2} \cdot\epsilon\right) \cdot \hat z_{t} + \frac{2}{\pi} \sin \left(\frac{\pi}{2} \cdot\epsilon\right) \cdot v_t(\hat z_t)
>$$
>
{: .example}

Another example is DDIM. Although it may appear complex, DDIM can be interpreted as a natural Euler sampler derived from a spherical interpolation.

> **Example 2. Natural Euler Sampler for DDIM**
>
> The discretized inference scheme of DDIM is a instance of natural Euler sampler for spherical interpolations satisfying $$\alpha_t^2 + \beta_t^2 = 1$$. Note that the inference update of DDIM is written in terms of the expected noise $$\hat{x}_{0\mid t}(x) = \mathbb{E}[X_0 \mid X_t = x]$$, we rewrite the update step using $$\hat{x}_{0 \mid t}$$: 
>
> $$
> \begin{aligned}
> \hat{z}_{t+\epsilon} &= \alpha_{t+\epsilon} \cdot\hat{x}_{1\vert t}(\hat{z}_t) + \beta_{t+\epsilon} \cdot \hat{x}_{0\vert t}(\hat{z}_t) \\
> &\overset{*}{=} \alpha_{t+\epsilon} \left( \frac{\hat{z}_t - \beta_t \cdot\hat{x}_{0\vert t}(\hat{z}_t)}{\alpha_t} \right) + \beta_{t+\epsilon} \cdot \hat{x}_{0\vert t}(\hat{z}_t) \\
> &= \frac{\alpha_{t+\epsilon}}{\alpha_t} \hat{z}_t + \left( \beta_{t+\epsilon} - \frac{\alpha_{t+\epsilon} \beta_t}{\alpha_t} \right) \hat{x}_{0\vert t}(\hat{z}_t)
> \end{aligned}
> $$
>
> where in $$\overset{*}{=}$$ we used $$\alpha_t \cdot \hat{x}_{1\vert t}(\hat{z}_t) + \beta_t\cdot \hat{x}_{0\vert t}(\hat{z}_t) = \hat{z}_t$$. We can slightly rewrite the update as:
>
> $$
> \frac{\hat{z}_{t+\epsilon}}{\alpha_{t+\epsilon}} = \frac{\hat{z}_t}{\alpha_t} + \left( \frac{\beta_{t+\epsilon}}{\alpha_{t+\epsilon}} - \frac{\beta_t}{\alpha_t} \right) \hat{x}_{0\vert t}(\hat{z}_t),
> $$
>
> which matches Equation 13 of <d-cite key="song2020denoising"></d-cite>.
{: .example}

## Equivalence of Natural Euler Trajectories

Natural Euler sampling preserves pointwise equivalences of discrete trajectory points across different interpolations:

> **Theorem 1. Equivalence of Natural Euler Trajectories**
> 
> Suppose $$\{X_t\}$$ and $$\{X_t'\}$$ are two interpolation processes contructed from the same couping, related by a pointwise transform $$X_t' = \phi_t(X_{\tau_t})$$. Consider the discrete trajectories $$\{\hat{z}_{t_i}\}_i$$ and $$\{\hat{z}_{t_i'}'\}_i$$, produced by the natural Euler samplers of rectified flows induced by $$\{X_t\}$$ and $$\{X_t'\}$$, on time grids $$\{t_i\}$$ and $$\{t_i'\}$$ respectively.
>
> If the time grids satisfy $$\tau(t_i') = t_i$$ for all $$i$$, and the initial conditions align via $$\hat{z}_{t_0}' = \phi(\hat{z}_{t_0})$$, then the **discrete** trajectories also match under the same transform:
>
> $$
> \hat{z}_{t_i'}' = \phi_{t_i}(\hat{z}_{t_i}) \quad \text{for all } i = 0,1,\ldots
> $$
{: .theorem}

Let $$\{X_t'\} = \texttt{Transform}(\{X_t\})$$ denote a pointwise transformation, and let $$\texttt{NaturalEulerRF}$$ represent the operation of generating discrete trajectories from a rectified flow ODE using the natural Euler sampler. Then:

$$
\texttt{NaturalEulerRF}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{NaturalEulerRF}(\{X_t\})).
$$

As for the DDIM sampler, once we rescale the time grids appropriately, its discrete trajectories become equivalent to those generated by the standard Euler method on the corresponding straight RF.

> **Example 3. Equivalence of Straight Euler and DDIM sampler**
>
> Consider the natural Euler sampler applied to a RF induced by an affine interpolation $$\{X_t' = \alpha'_t X_1 + \beta'_t X_0\}$$ using a uniform time grid $$t'_i = i/n$$. This procedure is equivalent to applying the standard (straight) Euler method to the straight RF (induced by $$\{X_t = tX_1 + (1 - t)X_0\}$$), but with a non-uniform time grid:
>
> $$
> t_i = \frac{\alpha'_{i/n}}{\alpha'_{i/n}+\beta'_{i/n}}.
> $$
>
> Conversely, starting from the straight RF and applying the standard Euler sampler on $$\{t_i\}$$, one can recover the natural Euler sampler for the affine interpolation by selecting a time grid $$\{t'_i\}$$ such that:
>
> $$
> t_i = \frac{\alpha'_{t'_{i}}}{\alpha'_{t'_{i}}+\beta'_{t'_{i}}}.
> $$
>
> Since DDIM is the natural Euler sampler under spherical interpolation, and the straight-interpolation counterpart corresponds to the standard Euler method, appropriately scaling the time grid for the straight RF reproduces the results of the DDIM sampler exactly.
>
{: .example}

Below, we compare two equivalent RFs: one induced by straight interpolation and the other induced by spherical interpolation. To ensure exact equivalence, we train a RF using the straight interpolation, then transform it into the spherical form.

<div class="l-body">
  <figure id="figure-3">
    <div style="display: flex;">
      <iframe src="{{ 'assets/plotly/discrete_vanilla_euler_4_step.html' | relative_url }}" 
              frameborder="0" 
              scrolling="no" 
              height="420px" 
              width="45%"></iframe>
      <iframe src="{{ 'assets/plotly/discrete_natural_euler_4_step.html' | relative_url }}" 
              frameborder="0" 
              scrolling="no" 
              height="420px" 
              width="45%"></iframe>
    </div>
    <figcaption>
      <a href="#figure-1">Figure 1</a>.
      Comparison of the Vanilla Euler sampler (left) and the Natural Euler sampler (right) on spherical RF. The left approximates each step using straight segments, while the right uses local curves for each step. Zoom in to observe the differences in detail.
    </figcaption>
  </figure>
</div>



<div class="l-body">
  <figure id="figure-2">
    <iframe src="{{ '/assets/plotly/discrete_natural_double_match.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="430px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-2">Figure 2</a>.
      Sampling with the Natural Euler sampler on both Straight and Spherical RF. By adjusting the time grid of the Straight RF using \(\tau_t\) (while maintaining a uniform grid for the Spherical RF), the final generated results are identical.
    </figcaption>
  </figure>
</div>

