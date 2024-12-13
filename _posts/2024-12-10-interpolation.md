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
  - name: Yule Duan

# 如果有文献，请指定bibliography文件
# bibliography: 2024-12-11-distill.bib

# 可选的目录配置
toc:
  - name: "Point-wisely Transformable Interpolations"
    subsections:
      - name: "TL; DR"
      - name: "Same Transform on Interpolations and Rectified Flows"
  - name: "Equivalence of Affine Interpolations"
    subsections:
      - name: "Straight, Spherical and DDIM interpolation"
      - name: "Pointwise Transformability Between Affine Interpolations"
      - name: "Converting Pretrained RF Velocity"
  - name: "Implications on Loss Functions"
    subsections:
      - name: "Straight vs Spherical: Same Train Time Weight"


---

The choice of the interpolation process can significantly impact inference performance and speed, and it may initially seem that this decision must be made during the pre-training phase. In this blog, however, we demonstrate that it is possible to convert between different affine interpolation schemes at inference time, without retraining the model. The **transformations** applied to the interpolation are **exactly the same** as those applied to the rectified flow. For affine interpolation schemes, this can be achieved with a simple rescaling of the time $$t$$ and the input $$x$$. Building on this, we will show that these interpolations yield essentially **equivalent** rectified flow dynamics and identical rectified couplings.

For a more comprehensive and rigorous discussion on this topic, please refer to Chapter 3 in the [Rectified Flow book]().

## Point-wisely Transformable Interpolations

### TL; DR

Assume that we are given an arbitrary coupling $(X_0, X_1)$ of source distribution $\pi_0$ and target distribution$\pi_1$. We first construct a time-differentialble interpolation process diefined by 

$$\{X_t\}:\{X_t=\alpha_t X_1 + \beta_t X_0, t\in[0,1]\}.$$ 

Then, the Rectified Flow $$\{Z_t\}$$ induced by $$\{X_t\}$$ is given by

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

This result implies that the rectified flows of pointwisely transformable interpolations are **essentially the same**, up to the same pointwise transformation. Furthermore, if two interpolations $$X_t = \texttt I_t(X_0, X_1)$$ and $$X'_t = \texttt I_t(X_0, X_1)$$ are constructed from the same coupling $$(X_0, X_1)$$, they yield same rectified coupling $$(Z_0, Z_1') = (Z_0, Z_1)$$.

Define $$\{X'_t\} = \texttt{Transform}(\{X_t\})$$ as the aforementioned pointwise transformation. The result then suggests that the rectification operation $$\texttt{Rectify}(\cdot)$$ is **equivariant** under these pointwise transforms:

$$
\texttt{Rectify}(\texttt{Transform}(\{X_t\})) = \texttt{Transform}(\texttt{Rectify}(\{X_t\})).
$$



### Same Transform on Interpolations and Rectified Flows

> **Definition 1**: Two stochastic processes $$\{X_t\}$$ and $$\{X'_t\}$$ are said to be **pointwisely transformable** if
>
> $$
> X'_t = \phi_t(X_{\tau_t}), \quad \forall t \in [0, 1],
> $$
>
> where $$\tau: [0,1] \to [0,1]$$ and $$\phi: [0,1] \times \mathbb{R}^d \to \mathbb{R}^d$$ for $$t \in [0,1]$$ are differentiable maps, and $$\phi_t$$ is invertible for all $$t \in [0,1]$$.


Building upon the notion of pointwise transformability, we have:

> **Theorem 1:** Assume that $$\{X_t\}$$ and $$\{X'_t\}$$ are pointwise transformable. Let $$\{v_t\}$$ and $$\{v'_t\}$$ be their respective RF velocity fields, and let $\phi$ and $t$ be the corresponding interpolation transformation maps. Then we have
>
> $$
> v'_t(x) = \partial_t \phi_t(\phi_t^{-1}(x)) + \nabla \phi_t(\phi_t^{-1}(x))^\top v_{\tau_t}(\phi_t^{-1}(x)) \dot{\tau}_t. \tag{1}
> $$
>
>
> In addition, let $$\{z_t\}$$ be a trajectory of the rectified flow of $$\{X_t\}$$, satisfying $$\frac{\mathrm d}{\mathrm dt} z_t = v_t(z_t).$$ Then a curve $$\{z'_t\}$$ satisfies $$z'_t = \phi_t(z_{\tau_t})$$,  $$\forall t \in [0, 1]$$ if and only if it is the trajectory of the rectified flow of $$\{X'_t\}$$ initialized from $$z'_0 = \phi_0(z_{\tau_0})$$.

Furthermore, under the additional requirement that $$\tau(0)=0$$, let $$\frac{\mathrm d}{\mathrm dt}Z_t=v_t(Z_t)$$ be the rectified flow of $$\{X_t\}$$ (initialized with $$Z_0=X_0$$ by default). Then $$Z'_t=\phi_t(Z_{\tau_t})$$ is the rectified flow of $$\{X_t'\}$$ with the specific initialization

$$
\frac{\mathrm d}{\mathrm dt} Z'_t = v'_t(Z_t'), \quad \forall t \in [0,1], \;\text{and}\; Z_0' = \phi_0(Z_{\tau_0}).
$$

This result has two implications:

**Same Transform between Interpolations and Rectified Flows**

Assume the same conditions as Theorem 1, with the additional assumption that $$\tau(0) = 0$$. Let $$\{Z_t\}$$ and $$\{Z'_t\}$$ be the rectified flows of $$\{X_t\}$$ and $$\{X'_t\}$$, respectively. Then $$Z'_t = \phi_t(Z_{\tau_t})$$ for all $$t \in [0, 1]$$.

**Equivalent Rectified Couplings**


If $$\{X_t\}$$ and $$\{X'_t\}$$ are constructed from the same coupling $$(X_0, X_1) = (X'_0, X'_1),$$ and they satisfy the condition in Theorem 1 with $$\tau(0) = 0$$ and $$\tau(1) = 1$$, then their rectified flow yields the same coupling, that is, $$ (Z_0, Z_1) = (Z'_0, Z'_1).$$

## Equivalence of Affine Interpolations

We now consider a specific class of interpolations called *affine interpolations*, defined as $$ X_t = \alpha_t X_1 + \beta_t X_0 $$ where $$\alpha_t$$ and $$\beta_t$$ satisfy the conditions $$\alpha_0 = \beta_1 = 0$$ and $$\alpha_1 = \beta_0 = 1$$, as well as $$\alpha_t$$ is monotonically increasing and $$\beta_t$$ monotonically decreasing.

### Straight, Spherical and DDIM interpolation

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

- This also yields a spherical trajectory, but with a non-uniform speed defined by $$\alpha_t$$.

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
> There is one unique solution of $$(\tau_t, \omega_t)$$ in $$(2)$$ since $$\alpha'_t / \beta'_t \geq 0$$  and $$\alpha_t / \beta_t$$ is strictly increasing for $$t \in [0,1]$$.

In practice, we determine the time scaling function $$\tau_t$$ in two ways. For simple cases, $$\tau_t$$ can be computed analytically. For more complex scenarios, a numerical approach, such as a [simple binary search](), can be used to find $$\tau_t$$ efficiently.  Check the notebook for implementation.

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


Substituting the notion of $$\tau$$ and $$\omega$$ into the theorem 1, we have:

> **Theorem 2**: Assume $$\{X_t\}$$ and $$\{X'_t\}$$ are two affine interpolations:
>
> 1) Their respective rectified flows $$\{Z_t\}$$ and $$\{Z'_t\}$$ satisfy:
>
> $$
> Z'_t = \omega_t^{-1} Z_{\tau_t}, \quad \forall t \in [0, 1].
> $$
>
> 2) Their rectified couplings are equivalent:
>
> $$
> (Z_0, Z_1) = (Z'_0, Z'_1).
> $$
>
> 3) Their RF velocity fields $$v_t$$ and $$v'_t$$ satisfy:
>
> $$
> v'_t(x) = \frac{1}{\omega_t} \left( \dot{\tau}_t v_{\tau_t}(\omega_t x) - \dot{\omega}_t x \right). \tag{3}
> $$

The figure below shows the conversion between the `straight` and `spherical` interpolations using a binary search method. Observe that once converted, the trajectory of the original `straight` interpolation matches perfectly with the newly derived `straight` curve, confirming that these interpolations are indeed pointwise transformable. See the flow book for explicit solution.

<div class="l-page">
  <iframe src="{{ '/assets/plotly/interp_affine_interp_conversion.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>



### Converting Pretrained RF Velocity

Now, let’s take a pretrained straight rectified flow and transform it into a curved trajectory.  See the notebook for implementation details.

<div class="l-page">
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

When matching the loss $$(4)$$ and $$(5)$$,  we find that these two training schemes are identical, except for the following time-weighting and reparametrization relationship:

$$
\eta'_t = \frac{\omega_t^2}{\dot{\tau}_t} \eta_{\tau_t},
\quad 
v'_t(x; \theta) = \frac{\dot{\tau}_t}{\omega_t} v_{\tau_t}(\omega_t x; \theta) - \frac{\dot{\omega}_t}{\omega_t} x.
$$

In other words, **training with different interpolation schemes simply only introduces different training time weights and model parameterizations.**

### Straight vs Spherical: Same Train Time Weight

In the case where $$X_t = tX_1 + (1-t)$$ is the straight interpolation, and $$X_t'=\alpha_t'X_1 + \beta'_t X_0$$ is the affine interpolation, when

$$
\dot \alpha_t' \beta_t' - \alpha_t \beta_t' = \text{const},
$$

we'll have $$\text{const} \cdot \eta_t' = \eta_{\tau_t}$$, meaning the training time weight scale remains the same across all time.

For example, this holds for spherical interpolation

$$
X'_t = \sin\left(\frac{\pi t}{2}\right) X_1 + \cos\left(\frac{\pi t}{2}\right) X_0,
$$

 where

$$
\eta'_t = \frac{2}{\pi} \eta_{\tau_t}, 
\quad 
\tau_t = \frac{\tan\left(\frac{\pi t}{2}\right)}{\tan\left(\frac{\pi t}{2}\right)+1}.
$$

In this case, training $$v_t$$ with straight interpolation using a uniform weight $$\eta_t = 1$$ is equivalent to training $$v'_t$$ with spherical interpolation, **also using a uniform weight** $$\eta'_t = 1$$, the only difference lies in the model parameterization:

$$
v'_t(x, \theta) = \frac{\pi \omega_t}{2} \left( v_{\tau_t}(\omega_t x, \theta) + \left( \cos\left(\frac{\pi}{2} t\right) - \sin\left(\frac{\pi}{2} t\right) \right) x \right).
$$

Given that the variable scaling factor $$\omega_t = (\sin(\frac{\pi}{2} t) + \cos(\frac{\pi}{2} t))^{-1}$$ is bounded in $$[1/\sqrt{2}, 1]$$, this reparameterization may not significantly impact performance. Overall, the choice of using straight or spherical interpolation might have limited impact in terms of training performance.

<div class="l-page">
  <iframe src="{{ '/assets/plotly/interp_straight_spherical_rf.html' | relative_url }}" 
          frameborder="0" 
          scrolling="no" 
          height="630px" 
          width="100%"></iframe>
</div>


Here, we independentely trained 2 rectified flow with mlp. Note that the final couplings $$(Z_0,Z_1)$$ and $$(Z_0',Z_1')$$ are the same.