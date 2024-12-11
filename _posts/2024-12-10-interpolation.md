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
  - name: Rectified Flow Research Group
    url: "https://example.com"
    affiliations:
      name: UT Austin

# 如果有文献，请指定bibliography文件
# bibliography: 2024-12-11-distill.bib

# 可选的目录配置
toc:
  - name: "Recap: Rectified Flow"
    subsections:
      - name: "Affine Interpolation"
      - name: "Rectified Flow Velocity"
      - name: "Example: Straight Rectified Flow"
  - name: "Interpolation Converter"
    subsections:
      - name: "Straight, Spherical and DDIM interpolation"
      - name: "Pointwise Transformability Between Affine Interpolations"
  - name: "Rectified Flow Converter"
    subsections:
      - name: "Equivariance of Rectified Flow"
      - name: "Converting Pretrained RF Velocity"
---

In this blog post, we will first demonstrate that all *affine interpolations* are point-wise transformable. We will then explain how transformations between these interpolations can be performed. Building upon this, we will show that these interpolations yield essentially **equivalent** rectified flow dynamics and identical rectified couplings. The key insight is that the transformations applied to the interpolation are **exactly the same** as those applied to the rectified flow.

Before diving deeper, let’s quickly review the core concepts of Rectified Flow. 

See this [notebook]() for implementation.

## Recap: Rectified Flow

### Affine Interpolation

Given observed samples $$X_0 \sim \pi_0$$ from a source distribution and $$X_1 \sim \pi_1$$ from a target distribution, we consider a class of *affine interpolations* $$X_t$$:

$$
X_t = \alpha_t \cdot X_0 + \beta_t \cdot X_1, \tag{1}
$$

where $$\alpha_t$$ and $$\beta_t$$ are time-dependent functions satisfying:

$$
\alpha_0 = \beta_1 = 0 \quad \text{and} \quad \alpha_1 = \beta_0 = 1. \tag{2}
$$

This form of interpolation is referred to as **affine interpolation**. In practice, it is desirable for $$\alpha_t$$ to be monotonically increasing and $$\beta_t$$ to be monotonically decreasing over the interval $$[0,1]$$.

The collection $$\{X_t\} = \{X_t : t \in [0,1]\}$$ defines an **interpolation process**, which smoothly transitions the distribution from $$X_0$$ at $$t=0$$ to $$X_1$$ at $$t=1$$.

While this process effectively creates a "bridge" between $$X_0$$ and $$X_1$$, it has a notable limitation: it is not "simulatable" using only the source data. To generate $$X_t$$ for some $$t \in (0,1)$$, one needs direct access to both $$X_0$$ and $$X_1$$, making it impossible to produce new target samples without having the target distribution already in hand.

<div class="l-page">
  <iframe src="{{ '/assets/plotly/interp_affine_interpolation.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

### Rectified Flow Velocity

To overcome this limitation and make the process "simulatable," we can train an Ordinary Differential Equation (ODE) model. The idea is to model the dynamics with an ODE defined as $$\dot{Z}_t = v_t(Z_t)$$, where $$v_t$$ is a time-dependent velocity field. We train $$v_t$$ to match the slope $$\dot{X}_t$$ of the interpolation process:

$$
\min_v \int_0^1 \mathbb{E}\left[\| \dot{X}_t - v_t(X_t) \|^2\right] \,\mathrm{d}t. \tag{3}
$$

The theoretical optimum is given by:

$$
v_t^*(x) = \mathbb{E}[\dot{X}_t \mid X_t = x], \tag{4}
$$

which is the **conditional average** of all slopes $$\dot{X}_t$$ of the interpolation process at a specific point $$X_t = x$$.

This conditional average ensures that the model preserves the marginal distributions. Intuitively, the ODE acts like a "rectifier," ensuring that the mass passing through small regions remains the same after the transformation. As a result, the distributions $$\{Z_t\}_t$$, obtained by simulating the ODE, match the distributions $$\{X_t\}_t$$ derived from the interpolation.

<div class="l-body">
  <img src="/assets/img/flow_in_out.png" alt="cross" style="max-width:100%;" />
</div>


We refer to the process $$\{Z_t\}$$ as the **rectified flow**, which is induced by the interpolation $$\{X_t\}$$. The rectified flow follows:

$$
Z_t = Z_0 + \int_0^t v(Z_s, s) \,\mathrm{d}s, \quad \forall t \in [0,1], \quad Z_0 = X_0, \tag{5}
$$

or more compactly,

$$
\{Z_t\} = \texttt{RectFlow}(\{X_t\}).
$$

### Example: Straight Interpolation

The `straight` interpolation, with coefficients $$\alpha_t = 1 - t$$ and $$\beta_t = t$$ yield:

$$
X_t = tX_1 + (1 - t)X_0, \quad \dot{X}_t = X_1 - X_0. \tag{6}
$$

<div class="l-page">
  <iframe src="{{ '/assets/plotly/interp_1rf_straight.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

## Interpolation Converter

However, $$\alpha_t$$ and $$\beta_t$$ are not limited to this specific choice. They can be **any** time-dependent functions, as long as they satisfy the conditions $$\alpha_0 = \beta_1 = 0$$ and $$\alpha_1 = \beta_0 = 1$$ (and maintain monotonicity). This implies there are infinitely many possible interpolation processes $$\{X_t\}$$ that can be used to induce rectified flows.

### Straight, Spherical and DDIM interpolation

**Straight Line Interpolation** (`straight` or `lerp`)

$$
\begin{aligned}
    \alpha_t & = t,       & \beta_t & = 1 - t \\
    \dot{\alpha}_t & = 1, & \dot{\beta}_t & = -1
\end{aligned} \tag{7}
$$

- This interpolation follows a straight line connecting the source and target distributions with a constant speed.

**Spherical Interpolation** (`spherical` or `slerp`)

$$
\begin{aligned}
    \alpha_t & = \sin\left(\frac{\pi}{2} t\right), & \beta_t & = \cos\left(\frac{\pi}{2} t\right) \\
    \dot{\alpha}_t & = \frac{\pi}{2} \cos\left(\frac{\pi}{2} t\right), & \dot{\beta}_t & = -\frac{\pi}{2} \sin\left(\frac{\pi}{2} t\right)
\end{aligned} \tag{8}
$$

- Spherical interpolation traces a curved path rather than a straight line.

**DDIM / VP ODE Interpolation**

$$
\alpha_t = \exp\left(- \frac{1}{4}a(1-t)^2 - \frac{1}{2}b(1-t)\right), \quad \beta_t = \sqrt{1 - \alpha_t^2}, \quad a=19.9, b=0.1 \tag{9}
$$
- This also yields a spherical trajectory, but with a non-uniform speed defined by $$\alpha_t$$.

### Pointwise Transformability Between Affine Interpolations

Consider two affine interpolation processes defined with same coupling $$(X_0, X_1)$$:

$$
X_t = \alpha_t X_1 + \beta_t X_0 \quad \text{and} \quad X_{t}' = \alpha_{t}' X_1 + \beta_{t}' X_0,
$$

we show that one can be smoothly transformed into the other, and vice versa. 

**1. Matching Time**

Note that

$$
\dot{\alpha}_t > 0, \quad \dot{\beta}_t < 0, \quad \alpha_t, \beta_t \in [0,1], \quad \forall t \in [0,1].
$$

These constraints imply that the ratio $$\alpha_t / \beta_t$$ is **strictly increasing** in $$[0,1]$$. Consequently, for any $$t$$ in the process $$\{X_t'\}$$, there exists a unique $$t'$$ in $$\{X_t\}$$ such that the ratio matches:

$$
\frac{\alpha_{t'}}{\beta_{t'}} = \frac{\alpha_t'}{\beta_t'}.
$$

Similarly, for any given $$t'$$ in $$\{X_t\}$$, we can find a unique $$t$$ in $$\{X_t'\}$$. This establishes a **bijective time mapping** $$\tau: t \mapsto t'$$.

**2. Matching Scales**

Once the times are matched, consider the ratio of the interpolations:

$$
\frac{X_{t'}}{X_t'} = \frac{\alpha_{t'}X_1 + \beta_{t'}X_0}{\alpha_t'X_1 + \beta_t'X_0}.
$$

Rewriting this ratio:

$$
\frac{X_{t'}}{X_t'} = \frac{\alpha_{t'}}{\alpha_t'} \cdot \frac{X_1 + \frac{\beta_{t'}}{\alpha_{t'}} X_0}{X_1 + \frac{\beta_t'}{\alpha_t'} X_0} = \frac{\alpha_{t'}}{\alpha_t'}.
$$

This shows that the scaling factor:

$$
\omega_t := \frac{\alpha_{t'}}{\alpha_t'} = \frac{\beta_{t'}}{\beta_t'} = \frac{X_{t'}}{X_t'},
$$

is well-defined and independent of $$X_0$$ and $$X_1$$.

> **Definition: Pointwise Transformability**
> 
> We say that two interpolation processes $$ \{X_t\} $$ and $$ \{X_t'\} $$ are **pointwise transformable** if:
>
> $$
> X_t' = \phi_t(X_{\tau_t}), \quad \forall t \in [0,1],
> $$
>
> where $$ \tau: t \mapsto \tau_t $$ is a monotonic (hence invertible) time transformation, and $$ \phi: (t, x) \mapsto \phi_t(x) $$ is an invertible transformation.


In the affine interpolations case:

- The time transformation is $$\tau_t = t'$$.
- The scaling transformation is $$\phi_t(X_t) = X_{\tau_t}/\omega_t$$.

We can determine the time scaling function $$\tau_t$$ in two ways. For simple cases, $$\tau_t$$ can be computed analytically. For more complex scenarios, a numerical approach, such as a [simple binary search](), can be used to find $$\tau_t$$ efficiently. 

<div class="l-page" style="display: flex;">
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


The figure below demonstrates the conversion between the `straight` and `spherical` interpolations using a binary search method. Observe that once converted, the trajectory of the original `straight` interpolation matches perfectly with the newly derived `straight` curve, confirming that these interpolations are indeed pointwise transformable.

<div class="l-page">
  <iframe src="{{ '/assets/plotly/interp_affine_interp_conversion.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>


## Rectified Flow Converter

### Equivariance of Rectified Flow

Interestingly, the very same transformation applied to the interpolation process $$\{X_t\}$$ can also be applied to the corresponding rectified flows. This observation leads us to the following theorem:

> **Theorem: Equivariance of Rectified Flow**
> 
> Suppose two processes $$\{X_t\}$$ and $$\{X'_t\}$$ are related pointwise by
> $$
> X'_t = \phi_t(X_{\tau_t}),
> $$
> 
> where $$\phi : (t, x) \mapsto \phi_t(x)$$ and $$\tau : t \mapsto \tau_t$$ are differentiable, invertible mappings. If their corresponding rectified flows are denoted by $$\{Z_t\}$$ and $$\{Z'_t\}$$, then they satisfy the analogous relationship
> 
> $$
> Z'_t = \phi_t(Z_{\tau_t}),
> $$
>
> provided that this relationship holds at initialization (i.e., $$Z'_0 = \phi_0(Z_0)$$).

**Implications**

This result demonstrates that the rectified flows associated with pointwise transformable interpolations are essentially **equivalent**, differing only by the same pointwise transformation. Moreover, if $$X_t = \mathcal{I}_t(X_0, X_1)$$ and $$X'_t = \mathcal{I}'_t(X_0, X_1)$$ are constructed from the same initial coupling $$(X_0, X_1)$$, they induce identical rectified couplings: $$(Z'_0, Z'_1) = (Z_0, Z_1)$$.

In short, if we define $$\{X'_t\} = \texttt{Transform}(\{X_t\})$$ as above, then the rectification operation $$\texttt{Rectify}(\cdot)$$ is **equivariant** under such transformations. Formally:

$$
\texttt{Rectify}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{Rectify}(\{X_t\})).
$$

For a more detailed derivation, please refer to Chapter 3 of the flow book.


### Converting Pretrained RF Velocity

Now, let’s take a pretrained straight rectified flow and transform it into a curved trajectory. The idea is to leverage our existing velocity predictions from the straight path and re-apply them to a new, curved interpolation. Here’s the general approach:

1. **Mapping to the New Trajectory**:  
   First, we find the corresponding position on the straight trajectory $$\{Z_t\}$$ for any given point $$Z'_t$$ on the curved trajectory $$\{Z'_t\}$$. This ensures we can reuse the pre-trained velocity field, which is defined along the straight path.

2. **Velocity Predictions**:  
   With the mapping established, we can now use the trained velocity model on $$\{Z_t\}$$ to obtain predictions $$\hat{X}_0$$ and $$\hat{X}_1$$. These predictions are crucial for ensuring that our curved interpolation still respects the underlying distributions.

3. **Updating the Trajectory**:  
   Finally, we advance the state along the curved trajectory using the updated interpolation $$\mathcal{I}(\hat{X}_0, \hat{X}_1)$$. This step integrates our predictions and ensures the resulting flow truly follows the curved path we’ve chosen.

By following these steps, we effectively "re-route" a rectified flow—originally trained on a straight interpolation—onto a different curve, all without needing to retrain the underlying model.

<div class="l-page">
  <iframe src="{{ '/assets/plotly/interp_1rf_straight_to_spherical.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

**Trajectory Considerations**

Looking at the figure above, we see that as the number of sampling steps increases, the trajectories for $$Z_1$$ and $$Z_1'$$ converge to the same points, and the mean squared error between them decreases, thereby validating the theorem.

However, even though different paths can lead to the same rectified endpoints $$Z_1$$, the intermediate trajectories $$\{Z_t\}$$ they follow are not the same. In practice, we must discretize these trajectories when running simulations, making perfect solutions unattainable. For this reason, choosing straighter trajectories is generally preferable: the straighter the path, the lower the discretization errors, and the more faithful the results.


### Train Two Rectified Flows: Equivalent Rectified Couplings

When two pointwise transformable interpolation processes are derived from the same coupling $$(X_0, X_1)$$, they will produce the same rectified coupling. In other words, no matter what interpolation you choose—provided it starts and ends at the same distributions—the rectified flow will align their endpoints.

> **Theorem. Equivalence of Rectified Couplings** 
> 
> Suppose we have two interpolation processes, $$\{X_t\}$$ and $$\{X'_t\}$$, that share the same initial and final conditions:
> 
> $$
> (X_0, X_1) = (X'_0, X'_1),
> $$
> 
> and suppose that their time transformation $$\tau$$ satisfies $$\tau(0) = 0$$ and $$\tau(1) = 1$$. Under these conditions, their corresponding rectified flows yield the same coupling:
> 
> $$
> (Z_0, Z_1) = (Z'_0, Z'_1).
> $$

To illustrate this result, let’s consider a simple 2D example and verify the theorem in action.

<div class="l-page">
  <iframe src="{{ '/assets/plotly/interp_straight_spherical_rf.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

This figure shows that when we independently train two rectified flows using the same data coupling $$(X_0, X_1)$$ but employ different interpolation schemes, the resulting couplings $$(Z_0,Z_1)$$ and $$(Z_0',Z_1')$$ are the same. Check the notebook for more details.