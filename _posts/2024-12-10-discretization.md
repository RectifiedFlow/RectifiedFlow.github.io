---
layout: distill
title: DDIM and Natural Euler Samplers
description: Even discretized trajectories are equivalent
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
bibliography: 2024-12-10-discritization.bib

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

Rectified flow learns an ODE of the form $$\mathrm{d}Z_t = v_t(Z_t; \theta)$$ by minimizing the loss between its velocity field and that of an interpolation process. As discussed in a [previous blog](../interpolation/#affine-interpolations-are-pointwise-transformable), different affine interpolations yield equivalent velocity fields and identical noise-data couplings.

In practice, we must approximate ODEs with **discrete solvers**. A standard approach is to use the Euler method: at each step, we approximate the local trajectory by a tangent line. For rectified flows induced by straight interpolations, this approach is intuitive. However, if the interpolation is nonlinear (e.g., spherical), a more natural choice is to approximate each step with a curved segment that matches the interpolation. We refer to these methods as **natural Euler samplers**.

Notably, the DDIM sampler can be interpreted as a natural Euler sampler under its corresponding interpolation. From this perspective, we do not need complicated coefficient derivations for DDIM’s inference steps.

A key property of natural Euler samplers is:

> If two interpolation processes are related by a pointwise transform, then **their discrete trajectories obtained through natural Euler sampling are also related by the same pointwise transform**, provided the time grids are appropriately scaled.
{: .definition}

In other words, **when using natural Euler samplers, switching the affine interpolation scheme *at inference time* is essentially adjusting the sampling time grid.** For DDIM, we obtain **exactly the same discrete samples** as those produced by a standard Euler solver applied to the rectified flow induced by straight interpolation, once we properly rescale the time grid.

For a more comprehensive and rigorous discussion on this topic, please refer to Chapter 5 in the [Rectified Flow Lecture Notes](https://github.com/lqiang67/rectified-flow/tree/main/pdf).

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

For affine interpolations $$X_t = \alpha_t X_1 + \beta_t X_0$$, this problem reduces to solving a simple $$2 \times 2$$ linear system. Moreover, due to the linearity of expectatins, the following conditional expectations also inherit this linear structure.

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

<div class="l-body-outset">
  <figure id="figure-1">
    <iframe src="{{ '/assets/plotly/discrete_euler.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-1">Figure 1</a>.
       Applying the standard Euler method with 10 uniform steps in \([0,1]\) to both the straight and spherical RFs results in significant final discrepancies.  
    </figcaption>
  </figure>
</div>

<div class="l-body-outset">
  <figure id="figure-2">
    <iframe src="{{ '/assets/plotly/discrete_natural_unmatch.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-2">Figure 2</a>.
       Using the natural Euler sampler with 10 uniform steps in \([0,1]\) produces nearly identical results for both the straight and spherical RFs, apart from minor differences due to slightly mismatched time parameterizations.  
    </figcaption>
  </figure>
</div>


<div class="l-body-outset">
  <figure id="figure-3">
    <iframe src="{{ '/assets/plotly/discrete_natural_match.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="630px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-3">Figure 3</a>.
      After adjusting the straight RF’s time grid using \(\tau_t\) (while keeping a uniform grid for the spherical RF), the natural Euler sampling results align exactly, confirming that the remaining discrepancies in Figure 2 were caused solely by mismatched time scaling.
    </figcaption>
  </figure>
</div>
