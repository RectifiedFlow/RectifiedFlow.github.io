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
  - name: "Natural Euler Sampler"
    subsections:
      - name: "Natural Euler Samplers for Affine Interpolations"
  - name: "Equivalence of Natural Euler Trajectories"

---
<!-- 
<div class="hero">
  <img src="/assets/img/teaser_post4.png" alt="Rectified Flow Overview" style="width: 100%; max-height: 500px; object-fit: cover; border-radius: 10px; margin-bottom: 20px;">
</div>
--> 

We know that the continuous-time ODE of the denoising diffusion implicit model (DDIM) is rectified flow (RF) with a time-scaled spherical interpolation. However, the discrete inference rule of DDIM does not exactly apply the vanilla Euler method, $$\hat Z_{t+\epsilon } = \hat Z_t + \epsilon \cdot v_t(\hat Z_t)$$, to the RF ODE $$\mathrm{d} Z_t = v_t(Z_t) \mathrm{d} t$$. Instead, it uses a somewhat complicated rule:

$$
\hat{Z}_{t+\epsilon} = \frac{\dot{\alpha}_t \beta_{t+\epsilon} - \alpha_{t+\epsilon} \dot{\beta}_t}{\dot{\alpha}_t \beta_t - \alpha_t \dot{\beta}_t} \hat{Z}_t + \frac{\alpha_{t+\epsilon} \beta_t - \alpha_t \beta_{t+\epsilon}}{\dot{\alpha}_t \beta_t - \alpha_t \dot{\beta}_t} v_t(\hat{Z}_t),  \tag{1}
$$

where $\alpha_t, \beta_t$ are the coefficients of the interpolation $$X_t = \alpha_t X_1 + \beta_t X_0$$ DDIM employs, which satisfy $$\alpha_t^2 + \beta_t^2 = 1$$.

What is the nature of Equation (1) as a discretization technique for ODEs? How is it related to the vanilla Euler method?

In this blog, we show that the DDIM inference is an instance of *natural Euler samplers*, which locally approximate ODEs using curved segments derived from the interpolation schemes employed during training. Additionally, we present a discrete-time extension of the equivariance result between pointwise transformable interpolations from [blog](https://rectifiedflow.github.io/blog/2024/interpolation/), showing that the natural Euler samplers of all affine interpolations are equivariant and produce (numerically) identical final outputs. Consequently, DDIM is, in fact, equivalent to the vanilla Euler method applied to a straight-line rectified flow.


## Natural Euler Samplers 

Rectified flow learns an ordinary differential equation (ODE) of the form $$\mathrm{d} Z_t = v_t(Z_t; \theta) \,\mathrm{d} t$$ by matching its velocity field $$v_t(x)$$ to the expected slope $$\mathbb{E}[\dot X_t  \mid X_t=x]$$ of an interpolation process $$\{X_t\}$$ that connects the noise $$X_0$$ and data $$X_1$$. As discussed in a [previous blog](../interpolation/#affine-interpolations-are-pointwise-transformable), different affine interpolations $$X_t = \alpha_t X_1 + \beta_t X_0$$ are pointwise transformable to one another and induce equivalent rectified flows with the same noise-data coupling.

In practice, continuous-time ODEs must be solved numerically, with **discrete solvers**. A common approach is the Euler method, which approximates the flow $$\{Z_t\}$$ on a discrete time grid $$\{t_i\}$$ by:

$$
\hat{Z}_{t_{i+1}} = \hat{Z}_{t_i} + (t_{i+1} - t_i) \cdot v_{t_i}(\hat{Z}_{t_i}),
$$

which yields a discrete trajectory $$\{\hat{Z}_{t_i}\}_i$$ composed of piecewise straight segments.

The piecewise straight approximation is natural for rectified flows induced from straight-line interpolation, $$X_t = t X_1 + (1-t)X_0$$. However, for a *curved* interpolation, it may be natural to approximates each step by a locally curved segment aligned with the corresponding interpolation process. 

<div class="l-body">
  <figure id="figure-svg" style="margin: 1em auto;">
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

Specifically, given a general interpolation scheme $$X_t= \mathtt{I}_t(X_0, X_1)$$, we update trajectory along a curve segment defined by $$\mathtt{I}$$:

$$
\hat{Z}_{t_{i+1}} = \mathtt{I}_{t_{i+1}}(\hat{X}_{0 \mid t_i}, \hat{X}_{1 \mid t_i}),
$$

where $$\hat{X}_{0 \mid t_i}$$ and $$\hat{X}_{1 \mid t_i}$$ are determined by  identifying the *unique interpolation curve* that passes through $$\hat{Z}_{t_i}$$. This curve has slope $$\partial_t \mathtt{I}_{t_i}(\hat{X}_{0 \mid t_i}, \hat{X}_{1 \mid t_i})$$ matching $$v_{t_i}(\hat{
Z}_{t_i})$$. In other words, $$\hat{X}_{0 \mid t_i}$$ and $$\hat{X}_{1 \mid t_i}$$ are the solutions of the following equation: 

$$
\begin{cases}
\hat{Z}_{t_i} = \mathtt{I}_{t_{i}}(\hat{X}_{0 \mid t_i}, \hat{X}_{1 \mid t_i}), \\[4px]
v_t(\hat{Z}_{t_i}) = \partial_t \mathtt{I}_{t_{i}}(\hat{X}_{0 \mid t_i}, \hat{X}_{1 \mid t_i}). \tag{2}
\end{cases}
$$

We first solve for $$\hat{X}_{0 \mid t_i}$$ and $$\hat{X}_{1 \mid t_i}$$ so that the interpolation connecting them matches the local velocity at $$t_i$$, then *advance* one step along this curved path to compute $$\hat{Z}_{t_{i+1}}$$.

We refer to this method as the **natural Euler sampler**.

### Natural Euler Samplers for Affine Interpolations

For affine interpolations, $$X_t = \alpha_t X_1 + \beta_t X_0$$, Equation (2) reduces to 

$$
\hat{Z}_{t} =\alpha_t\hat{X}_{1 \mid t} + \beta_t \hat{X}_{0 \mid t}, \quad
v_t(\hat{Z}_{t}) =\dot{\alpha}_t\hat{X}_{1 \mid t} + \dot{\beta}_t \hat{X}_{0 \mid t}. 
$$

This gives 

$$
 \hat X_{0|t} =  \frac{-\alpha_t v_t(\hat Z_t) +\dot \alpha_t \hat Z_t}{\dot \alpha_t \beta_t - \alpha_t \dot \beta_t },
 \hat X_{1|t} =  \frac{\beta_t v_t(\hat Z_t) - \dot \beta_t  \hat Z_t}{\dot \alpha_t \beta_t - \alpha_t \dot \beta_t }. 
$$

Plugging it into $$\hat Z_{t+\epsilon} = \alpha_{t+\epsilon} \hat X_{1\mid t} + \beta_{t+\epsilon} \hat X_{0\mid t}$$ yields Equation (1). 

In our code base, equations invovled in affine interpolations are automatically solved with a [affine interpolation solver](https://github.com/lqiang67/rectified-flow/blob/main/rectified_flow/flow_components/interpolation_solver.py), which allows us to implement methods like natural Euler samplers without hand derivaton using a few lines of [code](https://github.com/lqiang67/rectified-flow?tab=readme-ov-file#customized-samplers). 


<div class="l-body">
  <figure id="figure-1" style="margin: 1em auto;">
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
      Comparing the Vanilla Euler sampler (left) and the Natural Euler sampler (right) on spherical RF. The Vanilla Euler method approximates each step with a straight segment, while the Natural Euler method uses a locally curved segment derived from the spherical interpolation.
    </figcaption>
  </figure>
</div>

Here, we show the DDIM inference rule (1) can be viewed as a natural Euler method under spherical interpolations.

> **Example 1. Natural Euler Sampler for DDIM**
>
> DDIM’s discretized inference scheme can be seen as a natural Euler sampler for spherical interpolations where $$\alpha_t^2 + \beta_t^2 = 1$$. Note that the inference update of DDIM is written in terms of the expected noise $$\hat{x}_{0\mid t}(x) = \mathbb{E}[X_0 \mid X_t = x]$$, we rewrite the update step using $$\hat{x}_{0 \mid t}$$: 
>
> $$
> \begin{aligned}
> \hat{z}_{t+\epsilon} &= \alpha_{t+\epsilon} \cdot\hat{x}_{1\vert t}(\hat{z}_t) + \beta_{t+\epsilon} \cdot \hat{x}_{0\vert t}(\hat{z}_t) \\
> &\overset{*}{=} \alpha_{t+\epsilon} \left( \frac{\hat{z}_t - \beta_t \cdot\hat{x}_{0\vert t}(\hat{z}_t)}{\alpha_t} \right) + \beta_{t+\epsilon} \cdot \hat{x}_{0\vert t}(\hat{z}_t) \\
> &= \frac{\alpha_{t+\epsilon}}{\alpha_t} \hat{z}_t + \left( \beta_{t+\epsilon} - \frac{\alpha_{t+\epsilon} \beta_t}{\alpha_t} \right) \hat{x}_{0\vert t}(\hat{z}_t)
> \end{aligned}
> $$
>
> where in $$\overset{*}{=}$$ we used $$\alpha_t \cdot \hat{x}_{1\vert t}(\hat{z}_t) + \beta_t\cdot \hat{x}_{0\vert t}(\hat{z}_t) = \hat{z}_t$$. 
>
> We can slightly rewrite the update as:
> 
> $$
> \frac{\hat{z}_{t+\epsilon}}{\alpha_{t+\epsilon}} = \frac{\hat{z}_t}{\alpha_t} + \left( \frac{\beta_{t+\epsilon}}{\alpha_{t+\epsilon}} - \frac{\beta_t}{\alpha_t} \right) \hat{x}_{0\vert t}(\hat{z}_t),
> $$
>
> which precisely matches Equation 13 of <d-cite key="song2020denoising"></d-cite>.
>
>
{: .example}


> **Example 2. Natural Euler Sampler for Spherical Interpolation**
> 
> For the time-uniform spherical interpolation $$X_t = \sin\left(\frac{\pi}{2}t\right) X_1 + \cos\left(\frac{\pi}{2} \cdot\epsilon\right) X_0$$, the natural Euler update rule reduces to 
> 
>$$
>\hat Z_{t + \epsilon} =\cos\left(\frac{\pi}{2} \cdot\epsilon\right) \cdot \hat z_{t} + \frac{2}{\pi} \sin \left(\frac{\pi}{2} \cdot\epsilon\right) \cdot v_t(\hat z_t)
>$$
>
{: .example}

## Equivalence of Natural Euler Trajectories

A key feature of natural Euler sampling is that it *preserves* pointwise equivalences across different interpolation processes. In other words, if two interpolations $$\{X_t\}$$ and $$\{X_t'\}$$ are related by a pointwise transform, then their corresponding **discrete** trajectories under natural Euler remain related by the *same* transform—provided the time grids are properly scaled.

> **Theorem 1. Equivalence of Natural Euler Trajectories**
>
> Suppose $$\{X_t\}$$ and $$\{X_t'\}$$ are two interpolation processes contructed from the same couping, related by a pointwise transform $$X_t' = \phi_t(X_{\tau_t})$$. Let $$\{\hat{z}_{t_i}\}_i$$ and $$\{\hat{z}_{t_i'}'\}_i$$ be the discrete trajectories produced by the natural Euler samplers of the rectified flows induced by $$\{X_t\}$$ and $$\{X_t'\}$$ on time grids $$\{t_i\}$$ and $$\{t_i'\}$$, respectively.
>
> If $$\tau(t_i') = t_i$$ for all $$i$$, and the initial conditions align via $$\hat{z}_{t_0'}' = \phi_{t_0'}(\hat{z}_{\tau(t_0')})$$, then the discrete trajectories are also related by the same transform:
> 
> $$
> \hat{z}_{t_i'}' = \phi_{t_i'}(\hat{z}_{t_i}) \quad \text{for all } i = 0,1,\ldots
> $$
> 
> In particular, for affine interpolations, if $$\hat{z}_0 = \hat{z}_0'$$, then $$\hat{z}_1 = \hat{z}_1'$$ *even if* the intermediate trajectories differ step by step.
>
{: .theorem}

Let $$\{X_t'\} = \texttt{Transform}(\{X_t\})$$ denote a pointwise transformation between two interpolations, and let $$\texttt{NaturalEulerRF}$$ denote the operation of sampling a rectified flow ODE with natural Euler. Then:

$$
\texttt{NaturalEulerRF}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{NaturalEulerRF}(\{X_t\})).
$$

As for the DDIM sampler, once we rescale the time grids appropriately, its discrete trajectories become equivalent to those generated by the standard Euler method on the corresponding straight RF.

In the special case of DDIM, once we rescale the time grid appropriately, its discrete trajectories coincide with those obtained from the **vanilla (straight) Euler method** on the corresponding straight RF.

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

Below, we compare two equivalent RFs: one induced by straight interpolation and the other induced by spherical interpolation. To ensure exact equivalence, we first train a RF using the straight interpolation, then transform it into the spherical form.



<div class="l-body">
  <figure id="figure-2" style="margin: 1em auto;">
    <iframe src="{{ '/assets/plotly/discrete_natural_double_match.html' | relative_url }}" 
            frameborder="0" 
            scrolling="no" 
            height="430px" 
            width="100%">
    </iframe>
    <figcaption>
      <a href="#figure-2">Figure 2</a>.
      Running natural Euler samplers on both Straight and Spherical RFs. By adjusting the Straight RF's time grid via \(\tau_t\) (while keeping a uniform grid for the Spherical RF), we obtain identical final results. Furthermore, their intermediate trajectories can also be aligned point by point under their corresponding interpolation transforms.
    </figcaption>
  </figure>
</div>