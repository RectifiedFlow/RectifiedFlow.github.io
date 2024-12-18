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

Rectified flow learns an ODE of the form $$\mathrm{d}Z_t = v_t(Z_t; \theta)$$ by minimizing the loss between its velocity field and the slope of an interpolation process. As [previously discussed](../interpolation/#affine-interpolations-are-pointwise-transformable), affine interpolations yield essentially equivalent rectified flows thus identical couplings.

In practice, those ODE trajectories must be approximated by **discrete steps**. A standard approach is the Euler method: at each step, the local trajectory is approximated by its tangent line. For rectified flows induced by straight interpolation, this is a intuitive choice. However, if the interpolation is nonlinear (e.g., spherical), it may be more natural to approximate each step with a locally curved segment that matches the interpolation. We refer to such methods as **natural Euler samplers**.

Notably, the DDIM sampler can be viewed as a natural Euler sampler under its interpolation. In this perspective, we can understand DDIM without complex derivation of its coefficients.

A key property shares across pointwise transformable interpolations is:

> If two interpolation processes are pointwise transformable into one another using maps $$\phi$$ and $$\tau$$, then the **discrete sampling points produced by their respective natural Euler samplers are also pointwise transformable** under the same mappings, provided their time grids are related by a time scaling function $$\tau_t$$.
{: .definition}

In other words, **when using natural Euler samplers, changing the affine interpolation scheme *at inference time* is essentially adjusting the sampling time grid.** In the case of DDIM, one obtains **exactly the same results** as those produced by the vanilla Euler sampler (appropriately rescaling the time grid) applied to a rectified flow induced by a straight interpolation.

For a more comprehensive and rigorous discussion on this topic, please refer to Chapter 5 in the [Rectified Flow Lecture Notes](https://github.com/lqiang67/rectified-flow/tree/main/pdf).

## Affine Interpolation Solver

Given a coupling $$(X_0, X_1)$$ of source distirbution $$X_0 \sim \pi_0$$ and target unknown data distribution $$X_1 \sim \pi_1$$, we define an interpolation function formally:

> **Definition 1.** Let $$\mathtt I:[0,1] \times \mathbb R^d \times \mathbb R^d \mapsto \mathbb R^d$$ be a **interpolation function** satisfying
> 
> $$
> \mathtt I_0(x_0, x_1) = x_0, \quad \mathtt I_1(x_0, x_1)=x_1.
> $$
> 
>We construct the interpolation process $$\{X_t\}$$ by
> 
> $$
> X_t = \mathtt I_t(X_0, X_1).
> $$
> 
> We also require that $$\{X_t\}$$ is differentiable in time, that is, the time derivative exists pointwise
> 
> $$
> \dot{X}_t := \partial_t \mathtt{I}_t(X_0, X_1).
> $$
> 
{: .definition}

In many cases, given $$(X_t, \dot{X}_t)$$, we wish to recover $$(X_0, X_1)$$ that satisfy  

$$
\begin{cases}
X_t = \mathtt{I}_t(X_0, X_1), \\[6pt]
\dot{X}_t = \partial_t \mathtt{I}_t(X_0, X_1).
\end{cases}
$$

For affine interpolations $$(X_t = \alpha_t X_1 + \beta_t X_0)$$, this problem reduces to solving a simple $$2 \times 2$$ linear system. Moreover, because expectations are linear, conditional expectations under affine interpolation also inherit this linear structure.

> **Affine Interpolation Solvers.**  Define
>
> $$
> \begin{aligned}
> v_t(x) &:= \mathbb{E}[\dot{X}_t \mid X_t = x], &\text{(RF velocity field)} \\[6pt]
> \hat{x}_{0\mid t}(x) &:= \mathbb{E}[X_0 \mid X_t = x], &\text{(Expected noise $X_0$)} \\[6pt]
> \hat{x}_{1\mid t}(x) &:= \mathbb{E}[X_1 \mid X_t = x]. &\text{(Expected data $X_1$)}
> \end{aligned}
> $$
>
> Given any two of $$\{v_t, \hat x_{0\mid t}, \hat x_{1\mid t}, x_t\}$$ or $$\{\dot X_t, X_0, X_1, X_t\}$$, we can explicitly solve for the other two that satisfy
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

The vanilla Euler method approximates the flow $$\{Z_t\}$$ on a discrete time grid $$\{t_i\}$$ by locally linear steps:

$$
\hat{z}_{t_{i+1}} = \hat{z}_{t_i} + (t_{i+1} - t_i) \cdot v_{t_i}(\hat{z}_{t_i}).
$$

At each step, the solution is approximated by the straight line tangent to the rectified flow at $$\hat{z}_{t_i}$$.

In contrast, the **natural Euler sampler** replaces the straight line with an interpolation curve that is tangent at $$\hat{z}_{t_i}$$. The update rule becomes:

$$
\hat{z}_{t_{i+1}} = \mathtt{I}_{t_{i+1}}(\hat{x}_{0 \mid t_i}, \hat{x}_{1 \mid t_i}),
$$

where $$\hat{x}_{0 \mid t_i}$$ and $$\hat{x}_{1 \mid t_i}$$ are obtained through the affine interpolation solver. These serve as the estimated endpoints of the interpolation curve passing through $$\hat{z}_{t_i}$$ and matching the slope $$\partial \mathtt I_{t_i}(\hat{x}_{0 \mid t_i}, \hat{x}_{1 \mid t_i}) = v_{t_i}(\hat{z}_{t_i})$$ at time $$t_i$$. In other words, the natural Euler method updates the solution by advancing along a locally curved path that is consistent with underlying interpolation curve.

For instance, the natural euler sampler under spherical rectified flow can be derived as:


> **Example 1. Natural Euler Sampler for Spherical Interpolation**
> 
>$$
>\hat z_{t + \epsilon} =\cos\left(\frac{\pi}{2} \cdot\epsilon\right) \cdot \hat z_{t} + \frac{2}{\pi} \sin \left(\frac{\pi}{2} \cdot\epsilon\right) \cdot v_t(\hat z_t)
>$$
>
{: .example}

As a more involved example, consider the DDIM algorithm. Despite its complex appearance, DDIM’s inference scheme can be viewed as a natural Euler sampler:

> **Example 2. Natural Euler Sampler for DDIM**
>
> The discretized inference scheme of DDIM is the instance of natural Euler sampler for spherical interpolations satisfying $$\alpha_t^2 + \beta_t^2 = 1$$. The inference update of DDIM is written in terms of the expected noise $$\hat{x}_{0\mid t}(x) = \mathbb{E}[X_0 \mid X_t = x]$$, we rewrite the update steo using $$\hat{x}_{0 \mid t}$$: 
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
> which exactly matches Equation 13 of <d-cite key="song2020denoising"></d-cite>.
{: .example}

## Equivalence of Natural Euler Trajectories

The trajectory points obtained from natural Euler samplers are equivalent under pointwise transformations. 

> **Theorem 1. Equivalence of Natural Euler Trajectories**
> 
> Suppose $$\{X_t\}$$ and $$\{X_t'\}$$ are two interpolation processes contructed from the same couping and that they're related by a pointwise transform $$X_t' = \phi_t(X_{\tau_t})$$. Consider the trajectories $$\{\hat{z}_{t_i}\}_i$$ and $$\{\hat{z}_{t_i'}'\}_i$$, generated by applying the natural Euler method to the rectified flows induced by $$\{X_t\}$$ and $$\{X_t'\}$$, respectively, on time grids $$\{t_i\}$$ and $$\{t_i'\}$$.
>
> If the time grids satisfy $$\tau(t_i') = t_i$$ for all $$i$$, and the initial conditions align via $$\hat{z}_{t_0}' = \phi(\hat{z}_{t_0})$$, then the **discrete** trajectories also match under the same transform:
>
> $$
> \hat{z}_{t_i'}' = \phi_{t_i}(\hat{z}_{t_i}) \quad \text{for all } i = 0,1,\ldots
> $$
>
> In particular, applying the natural Euler method to a rectified flow induced by an affine interpolation $$\{X_t'\}$$ on a uniform grid $$t_i' = i/n$$ is equivalent to applying the standard (straight) Euler method to the rectified flow induced by the corresponding straight interpolation $$\{X_t\}$$, but with a non-uniform time grid $$t_i = \tau(i/n)$$.
{: .theorem}

This **discrete-level equivalence** extends the continuous-time theorem, ensuring that natural Euler samplers inherit the same invariances as the underlying rectified flow ODE.

Let $$\{X_t'\} = \texttt{Transform}(\{X_t\})$$ denote a pointwise transformation, and let $$\texttt{NaturalEulerRF}$$ represent the operation of generating discrete trajectories from a rectified flow ODE using the natural Euler sampler. Then:

$$
\texttt{NaturalEulerRF}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{NaturalEulerRF}(\{X_t\})).
$$

> **Example 3. Equivalence of Straight Euler and DDIM sampler**
>
> Since DDIM is the natural Euler sampler under spherical interpolation, and the vanllia Euler method is the natural Euler under the straight interpolation, they yield the same results under proper transform on the time grid. Specifically, the natural Euler sampler on an affine interpolation $$X_t' = \alpha'_t X_1 + \beta'_t X_0$$ using a uniform time grid $$t'_i = i/n$$ is equivalent to applying the vanilla (straight) Euler method to the straight RF (induced from $$X_t = tX_1 + (1 - t)X_0$$) but with a non-uniform time grid:
>
>$$
>t_i = \frac{\alpha'_{i/n}}{\alpha'_{i/n}+\beta'_{i/n}}
>$$
>
> Conversely, starting from the straight RF and using a vanilla Euler sampler on the time grid $$\{t_i\}$$, one can recover the DDIM sampler by finding a time grid $$\{t'_i\}$$ that satisfies:
>
> $$
> t_i = \frac{\alpha'_{t_{i'}}}{\alpha_{t_{i'}}'+\beta'_{t_i'}}
> $$
{: .example}

In the following figures, we compare two equivalent rectified flows (RFs): one induced by a straight interpolation and another by a spherical interpolation (which DDIM essentially represents via a time rescaling). We first train a straight RF and then convert it into a spherical RF, ensuring that they are exactly equivalent.

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
      Using the standard Euler method for both the straight and spherical RFs with 10 uniform steps in \([0,1]\), we see that, despite their theoretical equivalence, discretization errors accumulate, resulting in significantly different final samples.
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
       When using the natural Euler sampler with 10 uniform steps in \([0,1]\) for both the straight and spherical RFs, the resulting samples are nearly identical. Minor discrepancies arise because the time parameterizations do not perfectly align.
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
      After re-scaling the straight RF’s time grid using \(\tau_t\), (and the spherical one still uses uniform time grid) the natural Euler sampling trajectories match exactly between the straight and spherical RFs, confirming that the remaining differences were purely due to mismatched time parameterizations.
    </figcaption>
  </figure>
</div>

