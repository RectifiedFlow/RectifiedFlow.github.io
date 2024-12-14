---
layout: distill
title: Natural Euler Samplers
description: A Pointwise-Transformable Discretization of Flows
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
# bibliography: 2024-12-11-distill.bib

# 可选的目录配置
toc:
  - name: "Equivariance of Natural Euler Samplers"
    subsections:
      - name: "Natural Euler Samplers"
      - name: "Equivalence of Natural Euler Trajectories"

---

<div class="hero">
  <img src="/assets/img/teaser_post4.png" alt="Rectified Flow Overview" style="width: 100%; max-height: 500px; object-fit: cover; border-radius: 10px; margin-bottom: 20px;">
</div>



## Equivariance of Natural Euler Samplers

The Euler method can be viewed as approximating ODE trajectories piecewise by straight segments, where each step uses the tangent line at the current point to approximate the local curve. This local straight-line approximation is a natural choice for rectified flow induced by straight interpolation. However, if the rectified flow is induced by a curved interpolation scheme, it may be more natural to use local curve segments—derived from the same interpolation scheme—instead of straight lines. We refer to such approximation schemes as **natural Euler samplers**. The term "natural" is taken from natural gradient descent, to reflect the point that its equivariant under reparameterizations, we describe below. 

This blog will first introduce the general idea of **natural Euler samplers** and then show that the trajectories of natural Euler samplers are equivariant for pointwise transformable interpolations:

> If two interpolation processes are pointwise transformable into one another, then the discrete trajectories of their rectified flow (RF) using their corresponding natural Euler samplers are also pointwise transformable using the same mapping functions, provided their time grids are related by a time scaling function $$\tau_t$$.

This result implies that, when natural Euler samplers are employed, during inference time, **changing the affine interpolation scheme is essentially equivalent to altering the time grid**. Note that this equivalence is **beyond** the continuous-time limit of ODE trajectories. Even after discretization via Euler steps, once the sampled points are transformed accordingly, the resulting discrete points will match numerically — we literally get the same results. 

For a more comprehensive and rigorous discussion on this topic, please refer to Chapter 5 in the [Rectified Flow Lecture Notes](https://github.com/lqiang67/rectified-flow/tree/main/pdf).

### Natural Euler Samplers

Consider an [interpolation](/blog/2024/interpolation/#general-interpolation-function) process $$X_t=\texttt I_t(X_0, X_1)$$ with a rectified flow velocity field $$v_t$$. In the vanilla Euler method, the trajectories of the flow are approximated on a discrete time gird $$\{t_i\}_i$$ as:

$$
\hat z_{t_{i+1}} = \hat z_{t_i} + (t_{i+1} - t_i) v_t(\hat z_{t_i}),
$$

Here, the solution at each step is locally approxiamated by the straight line tangent to the rectified flow curve at point $\hat z_{t_i}$.

In the natural Euler method, we replace the straight line with an **interpolation curve** that is tangent at $$\hat z_{t_i}$$. The update rule becomes:

$$
\hat z_{t_{i+1}} = \texttt I_{t_{i+1}}(\hat x_{0 \mid t_i}, \hat x_{1\mid t_i}),
$$

where $\hat x_{0 \mid t_i}$ and $\hat x_{1 \mid t_i}$ are derived through equations from the specific interpolation $\texttt I$:

$$
    \begin{cases}
    \texttt I_{t_i}\bigl(\hat{x}_{0\mid t_i},\hat{x}_{1\mid t_i}\bigr) = \hat{z}_{t_{i+1}}, \\[6pt]
    \displaystyle \left.\frac{\partial}{\partial t} \texttt I_{t}\bigl(\hat{x}_{0\mid t_i},\hat{x}_{1\mid t_i}\bigr)\right|_{t=t_i} = v_{t_i}\bigl(\hat{z}_{t_i}\bigr).
    \end{cases}
$$

This two equations identifies the endpoints $$\hat{x}_{0 \mid t_i}$$ and $$\hat{x}_{1\mid t_i}$$ of the interpolation curve that passes through $$\hat{z}_{t_i}$$ and has a slope $$\partial \hat{z}_{t_i} = v_{t_i}(\hat{z}_{t_i})$$ at time $$t_i$$,  i.e. the interpolation curve is chosen so that it is tangent to the rectified flow at $$\hat{z}_{t_i}$$. In the case of affine interpolation, the solution takes a simple closed-form, as it reduces to solving a linear system in two variables.

>Example 1. Natural Euler Sampler for Spherical Interpolation
>
>$$
>\hat z_{t + \epsilon} =\cos\left(\frac{\pi}{2} \cdot\epsilon\right) \hat z_{t} + \frac{2}{\pi} \sin \left(\frac{\pi}{2} \cdot\epsilon\right) v_t(\hat z_t)
>$$

> Example 2. Natural Euler Sampler for DDIM
>
> The discretized inference scheme of DDIM is the instance of natural Euler sampler for spherical interpolations satisfying $$\alpha_t^2 + \beta_t^2 = 1$$. Note that the inference update of DDIM is written in terms of the expected noise $$\hat{x}_0\vert_t(x) = \mathbb{E}[X_0\vert X_t = x]$$. Hence, we also rewrite the update in terms of $$\hat{x}_{0|t}$$: 
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
> which exactly matches Equation 13 of **Song et al. [2020a]**.

### Equivalence of Natural Euler Trajectories

The trajectories obtained from natural Euler samplers are equivariant under pointwise transformations. 

> **Theorem 1.** Equivalence of Natural Euler Trajectories
> 
> Suppose we have two interpolation processes $$\{X_t\}$$ and $$\{X_t'\}$$ that are contructed from the same couping and related by a pointwise transform $$X_t' = \phi_t(X_{\tau_t})$$. Consider the trajectories $$\{\hat{z}_{t_i}\}_i$$ and $$\{\hat{z}_{t_i'}'\}_i$$, which are generated by applying the natural Euler method to the rectified flows induced by $$\{X_t\}$$ and $$\{X_t'\}$$, respectively, using time grids $$\{t_i\}$$ and $$\{t_i'\}$$.
>
> If the time grids satisfy $$\tau(t_i') = t_i$$ for all $$i$$, and the initial conditions align via $$\hat{z}_{t_0}' = \phi(\hat{z}_{t_0})$$, then the **discrete** trajectories match under the same transform:
>
> $$
> \hat{z}_{t_i'}' = \phi_{t_i}(\hat{z}_{t_i}) \quad \forall i = 0,1,\ldots
> $$
>
> In particular, applying the natural Euler method to the rectified flow induced by an affine interpolation $$\{X_t'\}$$ on a uniform grid $$t_i' = i/n$$ is equivalent to applying the standard Euler method to the rectified flow induced by the corresponding straight interpolation $$\{X_t\}$$, but using a non-uniform time grid $$t_i = \tau(i/n)$$.

This theorem strengthens the equivariance result of the rectified flow ODE given in the interpolation blog, as the ODE result can be viewed as the limiting case of the natural Euler method when the step size approaches zero.

Let $$\{X_t'\} = T(\{X_t\})$$ denote the pointwise transformation, and let $$\texttt{NaturalEuler}(\{Z_t\})$$ represent the mapping from a rectified flow ODE to its discrete trajectories produced by the natural Euler sampler. The **equivariance** property can be expressed as:

$$
\texttt{NaturalEulerRF}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{NaturalEulerRF}(\{X_t\})).
$$

*In other words, the natural Euler sampler commutes with pointwise transformations in the same manner as the underlying rectified flow ODE does, providing a stronger, discrete-level form of the equivariance established in continuous time.*

>Example 3. Equivalence of Straight Euler and DDIM sampler
>
>Since DDIM is the natural Euler sampler under spherical interpolation, and the vanllia Euler method is the natural Euler under the straight interpolation, they yield the same results under proper transform on the time grid. Specifically, the natural Euler sampler on an affine interpolation $$X_t' = \alpha'_t X_1 + \beta'_t X_0$$ using a uniform time grid $$t'_i = i/n$$ is equivalent to applying the vanilla (straight) Euler method to the straight RF (induced from $$X_t = tX_1 + (1 - t)X_0$$) but with a non-uniform time grid:
>
>$$
>t_i = \frac{\alpha'_{i/n}}{\alpha'_{i/n}+\beta'_{i/n}}
>$$
>
>Conversely, starting from the straight RF and using a vanilla Euler sampler on the time grid $$\{t_i\}$$, one can recover the DDIM sampler by finding a time grid $$\{t'_i\}$$ that satisfies:
>
> $$
> t_i = \frac{\alpha'_{t_{i'}}}{\alpha_{t_{i'}}'+\beta'_{t_i'}}
> $$
