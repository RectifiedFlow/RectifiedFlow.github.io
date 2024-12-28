---
layout: default
permalink: /
title: "Home"
nav: true
nav_order: 1
pagination:
  enabled: true
  collection: posts
  permalink: /page/:num/
  per_page: 5
  sort_field: date
  sort_reverse: false
  trail:
    before: 1 # The number of links before the current page
    after: 3  # The number of links after the current page
---


<div class="post" style="text-align: justify;">

  <!-- Floating Image -->
  <img
    src="assets/img/cutecat.png"
    alt="Description of image"
    style="
      float: right;
      margin-left: 20px;
      margin-bottom: 10px;
      max-width: 280px;
      height: auto;
    "
  >

  <!-- Text -->
  <p>
    <strong>Rectified flow</strong> offers a simplified yet unified perspective on flow- and diffusion-based generative modeling and has been widely applied to state-of-the-art image, audio, and video generation. It was derived by simplifying diffusion models to the extreme both conceptually and algorithmically, thereby uncovering a principled framework for rectifying transport maps to learn straightened ODE dynamics for fast discretized inference. 
  </p>

  <p>
    This series of tutorials on rectified flow addresses topics that are often sources of confusion
    and clarifies the connections with other methods.
  </p>

  <p>
    For those eager to dive deeper, we provide:
    <ul>
      <li>
        A comprehensive
        <a href="https://github.com/lqiang67/rectified-flow" target="_blank">codebase</a>
        for practical exploration.
      </li>
      <li>
        <a href="#" target="_blank">Lecture notes</a> containing detailed theoretical derivations.
      </li>
    </ul>
  </p>

  <p>
    If you have questions regarding the blog posts, codebase, or notes, please feel free to reach out
    via this <a href="mailto:rectifiedflow@gmail.com">email</a>.
  </p>
</div>


<hr style="border: 0.05px solid #ddd; margin: 20px 0;">

<!--
{% assign blog_name_size = site.blog_name | size %}
{% assign blog_description_size = site.blog_description | size %}

{% if blog_name_size > 0 or blog_description_size > 0 %}
  <div class="header-bar">
    <h1>{{ site.blog_name }}</h1>
    <h2>{{ site.blog_description }}</h2>
  </div>
{% endif %}

{% if site.display_tags and site.display_tags.size > 0 or site.display_categories and site.display_categories.size > 0 %}
  <div class="tag-category-list">
    <ul class="p-0 m-0">
      {% for tag in site.display_tags %}
        <li>
          <i class="fa-solid fa-hashtag fa-sm"></i>
          <a href="{{ tag | slugify | prepend: '/blog/tag/' | relative_url }}">{{ tag }}</a>
        </li>
        {% unless forloop.last %}
          <p>&bull;</p>
        {% endunless %}
      {% endfor %}
      {% if site.display_categories.size > 0 and site.display_tags.size > 0 %}
        <p>&bull;</p>
      {% endif %}
      {% for category in site.display_categories %}
        <li>
          <i class="fa-solid fa-tag fa-sm"></i>
          <a href="{{ category | slugify | prepend: '/blog/category/' | relative_url }}">{{ category }}</a>
        </li>
        {% unless forloop.last %}
          <p>&bull;</p>
        {% endunless %}
      {% endfor %}
    </ul>
  </div>
{% endif %}
-->

<!--
{% assign featured_posts = site.posts | where: "featured", "true" %}
{% if featured_posts.size > 0 %}
<br>
<div class="container featured-posts">
  {% assign is_even = featured_posts.size | modulo: 2 %}
  <div class="row row-cols-{% if featured_posts.size <= 2 or is_even == 0 %}2{% else %}2{% endif %}">
    {% for post in featured_posts %}
      <div class="col mb-4">
        <a href="{{ post.url | relative_url }}">
          <div class="card hoverable">
            <div class="row g-0">
              <div class="col-md-12">
                <div class="card-body">
                  <div class="float-right">
                    <i class="fa-solid fa-thumbtack fa-xs"></i>
                  </div>
                  <h3 class="card-title title-case">{{ post.title }}</h3>
                  <p class="card-text">{{ post.description }}</p>
                  {% if post.external_source == blank %}
                    {% assign read_time = post.content | number_of_words | divided_by: 180 | plus: 1 %}
                  {% else %}
                    {% assign read_time = post.feed_content | strip_html | number_of_words | divided_by: 180 | plus: 1 %}
                  {% endif %}
                  {% assign year = post.date | date: "%Y" %}
                  <p class="post-meta">
                    {{ read_time }} min read &nbsp; &middot; &nbsp;
                    <a href="{{ year | prepend: '/blog/' | prepend: site.baseurl}}">
                      <i class="fa-solid fa-calendar fa-sm"></i> {{ year }}
                    </a>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </a>
      </div>
    {% endfor %}
  </div>
</div>
<hr>
{% endif %}
-->

<ul class="post-list">

  {% if page.pagination.enabled %}
    {% assign postlist = paginator.posts %}
  {% else %}
    {% assign postlist = site.posts %}
  {% endif %}

  {% for post in postlist %}
    {% if post.external_source == blank %}
      {% assign read_time = post.content | number_of_words | divided_by: 180 | plus: 1 %}
    {% else %}
      {% assign read_time = post.feed_content | strip_html | number_of_words | divided_by: 180 | plus: 1 %}
    {% endif %}
    {% assign year = post.date | date: "%Y" %}
    {% assign tags = post.tags | join: "" %}
    {% assign categories = post.categories | join: "" %}

    <li>
      {% if post.thumbnail %}
        <div class="row">
          <div class="col-sm-8">
      {% endif %}

      <p class="post-bigtitle">
        {% if post.redirect == blank %}
          <a class="post-title" href="{{ post.url | relative_url }}">{{ post.title }}</a>
        {% elsif post.redirect contains '://' %}
          <a class="post-title" href="{{ post.redirect }}" target="_blank">{{ post.title }}</a>
          <svg
            width="2rem"
            height="2rem"
            viewBox="0 0 40 40"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M17 13.5v6H5v-12h6m3-3h6v6m0-6-9 9"
              class="icon_svg-stroke"
              stroke="#999"
              stroke-width="1.5"
              fill="none"
              fill-rule="evenodd"
              stroke-linecap="round"
              stroke-linejoin="round"
            ></path>
          </svg>
        {% else %}
          <a class="post-title" href="{{ post.redirect | relative_url }}">{{ post.title }}</a>
        {% endif %}
      </p>

      <p class="post-subtitle">{{ post.description }}</p>
      <p class="post-meta">
        {{ read_time }} min read &nbsp; &middot; &nbsp;
        {{ post.date | date: '%B %d, %Y' }}
        {% if tags != "" %}
          &nbsp; &middot; &nbsp;
          {% for tag in post.tags %}
            <a
              href="{{ tag | slugify | prepend: '/blog/tag/' | prepend: site.baseurl}}"
            >
              <i class="fa-solid fa-hashtag fa-sm"></i> {{ tag }}
            </a>
            {% unless forloop.last %}
              &nbsp;
            {% endunless %}
          {% endfor %}
        {% endif %}
      </p>

      {% if post.thumbnail %}
          </div>
          <div class="col-sm-4">
            <img
              class="card-img"
              src="{{ post.thumbnail | relative_url }}"
              alt="image"
              style="
              max-width: 300px;    /* 限制最大宽度 */
              width: 100%;         /* 宽度随容器自适应，如果容器比 300px 更窄，就等比缩小 */
              height: 100px;       /* 统一固定高度 */
              object-fit: contain;   /* 超出部分裁剪 */
            "
            >
          </div>
        </div>
      {% endif %}
    </li>
  {% endfor %}
</ul>

{% if page.pagination.enabled %}
  {% include pagination.liquid %}
{% endif %}

