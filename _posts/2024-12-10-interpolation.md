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
  - name: Qiang Liu
    url: "mailto:rectifiedflow@googlegroups.com"
    affiliations:
      name: UT Austin
  - name: Runlong Liao
  - name: Xixi Hu
  - name: Bo Liu

# 如果有文献，请指定bibliography文件
bibliography: 2024-12-10-interpolation.bib

# 可选的目录配置
toc:
  - name: "Point-wisely Transformable Interpolations"
    subsections:
      - name: "TL; DR"
      - name: "Same Transform on Interpolations and Rectified Flows"
  - name: "Equivalence of Affine Interpolations"
    subsections:
      - name: "General Interpolation Function"
      - name: "Straight, Spherical and DDIM interpolation"
      - name: "Pointwise Transformability Between Affine Interpolations"
      - name: "Converting Pretrained RF Velocity"
  - name: "Implications on Loss Functions"
    subsections:
      - name: "Straight vs Spherical: Same Train Time Weight"
---

The choice of interpolation process can significantly affect inference performance and speed, and it may initially appear that such a decision must be made during the pre-training stage. In this blog, however, we show that it is possible to convert between different affine interpolation schemes at inference time, without retraining the model. The **transformations** applied to the interpolation $$\{X_t\}$$ are **exactly the same** as those applied to the rectified flow $$\{Z_t\}$$. For affine interpolation schemes, this can be achieved by simply rescaling the time $t$ and the input $$x$$. Building on this, we will demonstrate that these interpolations yield essentially **equivalent** rectified flow dynamics and identical rectified couplings. Consequently, it suffices to adopt a simple form—such as the straight-line interpolation $$X_t = tX_1 + (1-t)X_0$$—while maintaining the flexibility to recover all affine interpolations through appropriate adjustments in time and parameterization.

For a more comprehensive and rigorous discussion on this topic, please refer to Chapter 3 in the [Rectified Flow Lecture Note](). Related observations and discussion can also be found in <d-cite key="karras2022elucidating,kingma2024understanding,shaulbespoke,gao2025diffusionmeetsflow"></d-cite>

## Point-wisely Transformable Interpolations

### TL; DR

Assume that we are given an arbitrary coupling $(X_0, X_1)$ of source distribution $\pi_0$ and target distribution$\pi_1$. With a time-differentialble interpolation process $$X_t = \texttt I_t(X_0, X_1)$$, the Rectified Flow $$\{Z_t\}$$ induced by $$\{X_t\}$$ is given by

$$
\mathrm d Z_t = v_t(Z_t), \quad \forall t \in [0,1], \quad \text{starting from } Z_0 = X_0,
$$

where $$v_t$$ is obtained by matching the slope $$\dot X_t$$ of the interpolation process:

$$
\min_v \int_0 ^1 \mathbb E\left[
\left\|
\dot X_t - v_t(X_t)
\right\|^2
\right] \mathrm d t.
$$

The theoretical minimum is achieved by $$v^*_t(x) = \mathbb E[\dot X_t \mid X_t = x]$$.

We show that, if two processes $$\{X_t\}$$ and $$\{X'_t\}$$, generated with different interpolation schemes, are related pointwise by

$$
X'_t = \phi_t(X_t),
$$

for some differentiable and invertible maps $$\phi: (t, x) \mapsto \phi_t(x)$$ and $$\tau: t \mapsto \tau_t$$, then their corresponding rectified flows $$\{Z_t\}$$ and $$\{Z'_t\}$$ satisfy the **same** relationship:

$$
Z'_t = \phi_t(Z_{\tau_t}),
$$

provided that this relation holds at initialization, i.e., $$Z'_0 = \phi_t(Z_0)$$.

This result implies that the rectified flows of pointwisely transformable interpolations are **essentially the same**, up to the same pointwise transformation. Furthermore, if two interpolations $$X_t = \texttt I_t(X_0, X_1)$$ and $$X'_t = \texttt I'_t(X_0, X_1)$$ are constructed from the same coupling $$(X_0, X_1)$$, they yield same rectified coupling $$(Z_0, Z_1') = (Z_0, Z_1)$$.

Define $$\{X'_t\} = \texttt{Transform}(\{X_t\})$$ as the aforementioned pointwise transformation. The result then suggests that the rectification operation $$\texttt{Rectify}(\cdot)$$ is **equivariant** under these pointwise transforms:

$$
\texttt{Rectify}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{Rectify}(\{X_t\})).
$$

### Same Transform on Interpolations and Rectified Flows

> **Definition 1**. Two interpolation processes $$\{X_t\}$$ and $$\{X'_t\}$$ are said to be **pointwisely transformable** if
>$$
> X'_t = \phi_t(X_{\tau_t}), \quad \forall t \in [0, 1],
> $$
> 
>where $$\tau: [0,1] \to [0,1]$$ and $$\phi: [0,1] \times \mathbb{R}^d \to \mathbb{R}^d$$ for $$t \in [0,1]$$ are differentiable maps, and $$\phi_t$$ is invertible for all $$t \in [0,1]$$.

Building upon the notion of pointwise transformability, we have:

> **Theorem 1**. Assume that $$\{X_t\}$$ and $$\{X'_t\}$$ are pointwise transformable. Let $$\{v_t\}$$ and $$\{v'_t\}$$ be their respective RF velocity fields, and let $\phi$ and $t$ be the corresponding interpolation transformation maps. Then we have
>$$
> v'_t(x) = \partial_t \phi_t(\phi_t^{-1}(x)) + \nabla \phi_t(\phi_t^{-1}(x))^\top v_{\tau_t}(\phi_t^{-1}(x)) \dot{\tau}_t. \tag{1}
> $$
> 
>In addition, let $$\{z_t\}$$ be a trajectory of the rectified flow of $$\{X_t\}$$, satisfying $$\frac{\mathrm d}{\mathrm dt} z_t = v_t(z_t).$$ Then a curve $$\{z'_t\}$$ satisfies $$z'_t = \phi_t(z_{\tau_t})$$, $$\forall t \in [0, 1]$$ if and only if it is the trajectory of the rectified flow of $$\{X'_t\}$$ initialized from $$z'_0 = \phi_0(z_{\tau_0})$$.

Furthermore, under the additional requirement that $$\tau(0)=0$$, let $$\frac{\mathrm d}{\mathrm dt}Z_t=v_t(Z_t)$$ be the rectified flow of $$\{X_t\}$$ (initialized with $$Z_0=X_0$$ by default). Then $$Z'_t=\phi_t(Z_{\tau_t})$$ is the rectified flow of $$\{X_t'\}$$ with the specific initialization

$$
\frac{\mathrm d}{\mathrm dt} Z'_t = v'_t(Z_t'), \quad \forall t \in [0,1], \;\text{and}\; Z_0' = \phi_0(Z_{\tau_0}).
$$

This result has two implications:

1. *Identical Transformations for Interpolations and Rectified Flows:*  
   Under the same conditions as Theorem 1, and assuming $$\tau(0) = 0$$, let $$\{Z_t\}$$ and $$\{Z'_t\}$$ be the rectified flows corresponding to $$\{X_t\}$$ and $$\{X'_t\}$$, respectively. Then we have:

   $$
   Z'_t = \phi_t(Z_{\tau_t}) \quad \text{for all } t \in [0,1].
   $$

   In other words, the transformation applied to $$\{X_t\}$$ is exactly the same transformation that applies to $$\{Z_t\}$$.

2. *Equivalent Rectified Couplings:*  
   If $$\{X_t\}$$ and $$\{X'_t\}$$ are constructed from the same coupling $$(X_0, X_1) = (X'_0, X'_1)$$ and meet the conditions of Theorem 1 with $$\tau(0) = 0$$ and $$\tau(1) = 1$$, then their rectified flows produce the same coupling. Specifically:

   $$
   (Z_0, Z_1) = (Z'_0, Z'_1).
   $$

## Equivalence of Affine Interpolations

### General Interpolation Function

> **Definition 2.** Consider a function 
>
> $$
> \mathtt{I} : [0, 1] \times \mathbb{R}^d \times \mathbb{R}^d \to \mathbb{R}^d,
> $$
>
> denoted by $$\mathtt{I}_t(x_0, x_1)$$. We say $$\mathtt{I}$$ is an *interpolation function* if it satisfies:
>
> $$
> \mathtt{I}_0(x_0, x_1) = x_0 \quad \text{and} \quad \mathtt{I}_1(x_0, x_1) = x_1 \quad \text{for all } x_0, x_1 \in \mathbb{R}^d.
> $$
>
> Given an interpolation function $$\mathtt{I}$$ and a coupling $$(X_0, X_1)$$, the associated interpolation process $$\{X_t\}$$ is defined by:
>
> $$
> X_t = \mathtt{I}_t(X_0, X_1).
> $$


### Straight, Spherical and DDIM interpolation

We now consider a specific class of interpolations called _affine interpolations_, defined as $$ X_t = \alpha_t X_1 + \beta_t X_0 $$ where $$\alpha_t$$ and $$\beta_t$$ satisfy the conditions $$\alpha_0 = \beta_1 = 0$$ and $$\alpha_1 = \beta_0 = 1$$, as well as $$\alpha_t$$ is monotonically increasing and $$\beta_t$$ monotonically decreasing.

**Straight Line Interpolation** (`straight` or `lerp`)

$$
\begin{aligned}
    \alpha_t & = t,       & \beta_t & = 1 - t \\
    \dot{\alpha}_t & = 1, & \dot{\beta}_t & = -1
\end{aligned}
$$

- This interpolation follows a straight line connecting the source and target distributions with a constant speed.

**Spherical Interpolation** (`spherical` or `slerp`)

$$
\begin{aligned}
    \alpha_t & = \sin\left(\frac{\pi}{2} t\right), & \beta_t & = \cos\left(\frac{\pi}{2} t\right) \\
    \dot{\alpha}_t & = \frac{\pi}{2} \cos\left(\frac{\pi}{2} t\right), & \dot{\beta}_t & = -\frac{\pi}{2} \sin\left(\frac{\pi}{2} t\right)
\end{aligned}
$$

- Spherical interpolation traces a curved path rather than a straight line.

**DDIM / VP ODE Interpolation**

$$
\alpha_t = \exp\left(- \frac{1}{4}a(1-t)^2 - \frac{1}{2}b(1-t)\right), \quad \beta_t = \sqrt{1 - \alpha_t^2}, \quad a=19.9, b=0.1
$$

- DDIM interpolation also takes a spherical trajectory, but with a non-uniform speed defined by $$\alpha_t$$.

### Pointwise Transformability Between Affine Interpolations

We now show that **all affine interpolations are pointwise transformable** by appropriately scaling both the time and the input. Then, according to the two corollaries above, their rectified flows can be transformed pointwise using the same mappings as those used between the interpolations, ultimately yielding the same rectified couplings. This is also observed by other authors.

> Consider two affine interpolation processes of same coupling $$(X_0, X_1)$$:
>
> $$
> X_t = \alpha_t X_1 + \beta_t X_0 \quad \text{and} \quad X_{t}' = \alpha_{t}' X_1 + \beta_{t}' X_0,
> $$
>
> Then we have
>
> $$
> X_t' = \frac{1}{\omega_t} X_{\tau_t}, \quad \forall t \in [0,1],
> $$
>
> where $$\tau_t$$ and $$\omega_t$$ are found by solving:
>
> $$
> \frac{\alpha_{\tau_t}}{\beta_{\tau_t}} = \frac{\alpha'_t}{\beta'_t}, \quad \omega_t = \frac{\alpha_{\tau_t}}{\alpha'_t} = \frac{\beta_{\tau_t}}{\beta'_t}, \quad \forall t \in (0, 1) \tag{2}
> $$
>
> with the boundary condition:
>
> $$
> \omega_0 = \omega_1 = 1, \quad \tau_0 = 0, \quad \tau_1 = 1.
> $$
>
> There is one unique solution of $$(\tau_t, \omega_t)$$ in $$(2)$$ since $$\alpha'_t / \beta'_t \geq 0$$ and $$\alpha_t / \beta_t$$ is strictly increasing for $$t \in [0,1]$$.

In practice, we determine the time scaling function $$\tau_t$$ in two ways. For simple cases, $$\tau_t$$ can be computed analytically. For more complex scenarios, a numerical approach, such as a [simple binary search](), can be used to find $$\tau_t$$ efficiently.

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

The figure below shows the conversion between the `straight` and `spherical` interpolations using a binary search method. Observe that once converted, the trajectory of the original `straight` interpolation matches *perfectly* with the newly derived `straight` curve, confirming that these interpolations are indeed pointwise transformable.

<div class="l-body-outset">
  <iframe src="{{ '/assets/plotly/interp_affine_interp_conversion.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

Substituting the notion of $$\tau$$ and $$\omega$$ into the theorem 1, we have:

> **Example 1.** Converting straight interpolation into affine ones.
>
> Consider the straight interpolation $$X_t=tX_1 + (1-t)X_0$$ with $$\alpha_t=t$$ and $$\beta_t=1-t$$. We aim to transform this interpolation into another affine interpolation $$X_t'=\alpha_t' X_1 + \beta_t' X_0$$. By Solving the equations:
>
> $$
> \omega_t = \frac{\tau_t}{\alpha_t'} = \frac{1 - \tau_t}{\beta_t'},
> $$
>
> we obtain:
>
>$$
> \tau_t = \frac{\alpha'_t}{\alpha'_t + \beta_t'}, \quad \omega_t = \frac{1}{\alpha_t' + \beta_t'}
>$$
>
> The velocity field $$v_t(x)$$ is transformed into $$v'_t(x)$$ as follows:
>
> $$
> v'_t(x) = \frac{\dot \alpha_t' \beta_t' - \alpha'_t \dot \beta_t'}{\alpha_t' + \beta_t'} \cdot v_{\tau_t}(\omega_t x) + \frac{\dot \alpha_t' + \dot \beta_t'}{\alpha_t' + \beta_t'} \cdot x
> $$

### Converting Pretrained RF Velocity

Now, let’s take a pretrained straight rectified flow and transform it into a curved trajectory. See the notebook for implementation details.

> **Theorem 2**. Assume $$\{X_t\}$$ and $$\{X'_t\}$$ are two affine interpolations:
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
  <iframe src="{{ '/assets/plotly/interp_1rf_straight_to_spherical.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

**Trajectory Considerations**
As the number of sampling steps increases, the trajectories for $$Z_1$$ and $$Z_1'$$ should converge to the same points, and the mean squared error between them should also decrease.

However, even though different paths theoretically lead to the same rectified endpoint $$Z_1$$, the intermediate trajectories $$\{Z_t\}$$ they follow are not identical. In practice, when running simulations, we must discretize these trajectories, making perfect solutions unattainable. For this reason, **choosing straighter trajectories is generally preferable**: the straighter the path, the lower the discretization error, and the more faithful the results. Thanks to the transformation relations described above, it is possible to convert the interpolation scheme of a pretrained model without retraining, enabling the identification of a scheme that yields straighter trajectories for $$\{Z_t\}$$.

## Implications on Loss Functions

Assume that we have trained a model $$\hat{v}_t$$ for the RF velocity field $$v_t$$ under an affine interpolation. Using the formulas from the previous section, we can convert it to a model $$\hat{v}'_t$$ for $$v'_t$$ corresponding to a different interpolation scheme at the post-training stage. This raises the question of what properties the converted model $$\hat{v}'_t$$ may have compared to the models trained directly on the same interpolation, and whether it suffers from performance degradation due to the conversion.

We show here that using different affine interpolation schemes during training is equivalent to applying **different time-weighting** in the loss function, as well as an affine transform on the parametric model. Unless $$\omega_t$$ and $$\tau_t$$ are highly singular, the conversion does not necessarily degrade performance.

Specifically, assume we have trained a parametric model $$v_t(x; \theta)$$ to approximate the RF velocity $$v_t$$ of interpolation $$X_t = \alpha_t X_1 + \beta_t X_0$$, using the mean square loss:

$$
\mathcal L(\theta) = \int_0^1 \mathbb E\left[
\eta_t \left \| \dot X_t - v_t(X_t;\theta)\right\|^2
\right] \mathrm dt \tag{4}
$$

After training, we may convert the obtained model $$v_t(x; \theta)$$ to an approximation of $$v'_t$$ of a different interpolation $$X'_t = \alpha_t X_1 + \beta_t X_0$$ via:

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

For example, this condition holds in the case of spherical interpolation:

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
> In this case, training $$v_t$$ with the straight interpolation using a uniform weight $$\eta_t = 1$$ is equivalent to training $$v'_t$$ with the spherical interpolation, also with a uniform weight $$\eta'_t = 2 /\pi$$. The sole difference lies in the model’s parameterization:
>
> $$
> v'_t(x, \theta) = \frac{\pi \omega_t}{2} \left( v_{\tau_t}(\omega_t x, \theta) + \left( \cos\left(\frac{\pi t}{2}\right) - \sin\left(\frac{\pi t}{2}\right) \right) x \right),
> $$
>
> where $$\omega_t = (\sin(\frac{\pi t}{2}) + \cos(\frac{\pi t}{2}))^{-1}$$ is bounded within $$[1/\sqrt{2}, 1]$$. Thus, this reparameterization may not significantly affect performance. Overall, choosing between straight or spherical interpolation seems to have **limited practical impact** on training outcomes.

<div class="l-body-outset">
  <iframe src="{{ '/assets/plotly/interp_straight_spherical_rf.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>

In our experiments, we independently trained two rectified flows using MLPs. Since both used the equivalent time-weighting scheme, the resulting couplings were nearly identical.
