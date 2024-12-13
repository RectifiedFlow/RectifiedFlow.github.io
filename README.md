# RectifiedFlow Blog Page

## Installtion

下面对上述安装与本地预览 Jekyll 项目流程进行总结（以 macOS 为例）：

### 安装 Ruby 环境

macOS 自带 Ruby 版本较旧且系统级安装位置不适合安装 Gems。建议通过 Homebrew 安装用户级 Ruby 环境：

```shell
brew install ruby
```

安装完成后根据提示配置 PATH（确保 `/opt/homebrew/opt/ruby/bin` 在 `PATH` 中）。

### 安装 Bundler：

在确保使用的是新安装的 Ruby 后，安装 Bundler：

```shell
gem install bundler
```

### 项目依赖安装：

在项目根目录（有 Gemfile 的位置）执行：

```shell
bundle install
```

### 安装 ImageMagick（若需要处理图像）：

```shell
brew install imagemagick
```

移除或修改无用插件与标签：若不需要 jekyll-twitter-plugin，从 Gemfile 和 \_config.yml 的 plugins: 中删除该插件。 删除内容文件中 {% twitter ... %} 标签避免报错。若不需要 Jupyter Notebook 支持，则删除 jekyll-jupyter-notebook 插件和相关 .ipynb 文件；或安装 Jupyter：

```shell
pip install jupyter
```

## 本地预览网站：

```shell
bundle exec jekyll serve
```

根据出现的 localhost link 本地预览change。

## 添加Blogs

请在 `_posts` 下，copy-paste 此目录下任何blog post修改即可。举例，新添加的file叫做 `2024-12-24-newblogname.md` （注意这里需要按照YYYY-MM-DD-NAME.md)， 如果需要添加references, 可以在 `_bibliography` 和 `assets/bibliography`下面同时加入一个`2024-12-24-newblogname.bib`的file， 然后在里面可以使用正常copy-pasted的bibtext (e.g., from Google Scholar or Semantic Scholar). 然后使用`<d-cite key="Liu2022FlowSA"></d-cite>` 在正文Markdown即可。会自动生成底部reference list和一个hoverable的reference。注意同时需要在 `2024-12-24-newblogname.md`这个file的开头layout里添加
```yaml
---
layout: distill
...
bibliography: 2024-12-06-intro.bib
...
---
```

## 修改Profile

在`_pages`下有各种.md files可以修改。首页在`about.md`。具体的一些formatting参数在可在`_config.yml`里修改。

## CI & CD

为了防止 CI 错误，需要确保网站中的所有超链接都是可访问的。如果有需要忽略检查的链接，需要放置在 `.lycheeignore` 文件中。Commit 前，还需要运行

```sh
npx prettier . --write
```

来格式化 Markdown 文件。
