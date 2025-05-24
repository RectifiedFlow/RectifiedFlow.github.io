# RectifiedFlow Blog Page

## Source

This is adapted from [al-folio](https://github.com/alshedivat/al-folio)

## Installtion

Here is a summary of the steps to install and preview a Jekyll project locally (using macOS as an example):

### Install Ruby Environment

The default Ruby version on macOS is outdated, and its system-level installation location is not suitable for installing Gems. It is recommended to install a user-level Ruby environment via Homebrew:

```shell
brew install ruby
```

After installation, follow the instructions to configure the PATH (make sure /opt/homebrew/opt/ruby/bin is included in the PATH).

### Install Bundler:

Once you ensure you are using the newly installed Ruby, install Bundler:

```shell
gem install bundler
```

### Install Project Dependencies:

Run the following command in the project root directory (where the Gemfile is located):

```shell
bundle install
```

### Install ImageMagick (if image processing is needed):

```shell
brew install imagemagick
```

Remove or Modify Unnecessary Plugins and Tags

If the jekyll-twitter-plugin is not needed, remove it from the Gemfile and the plugins: section of _config.yml.

Remove any {% twitter ... %} tags in the content files to avoid errors.

If support for Jupyter Notebook is not needed, remove the jekyll-jupyter-notebook plugin and any related .ipynb files.

If Jupyter support is needed, you can install Jupyter with:
```shell
pip install jupyter
```

## Local Website Preview


```shell
eval "$(rbenv init -)"
rbenv rehash
bundle exec jekyll serve
```

Use the localhost link that appears in the terminal to preview the site locally.

## Adding Blog Posts

To add a new blog post, copy and modify any existing blog post in the _posts directory. For example, if the new file is named 2024-12-24-newblogname.md, make sure it follows the format YYYY-MM-DD-NAME.md.

If references are required, add a corresponding .bib file in both the _bibliography and assets/bibliography directories. The file should be named 2024-12-24-newblogname.bib. You can copy and paste BibTeX entries from sources like Google Scholar or Semantic Scholar.

To cite references in the Markdown file, use the following format:

<d-cite key="Liu2022FlowSA"></d-cite>

This will automatically generate a reference list at the bottom of the post and a hoverable reference in the text.

In addition, ensure that the YAML front matter at the beginning of the 2024-12-24-newblogname.md file contains the following layout configuration:

```yaml
---
layout: distill
bibliography: 2024-12-06-intro.bib
---
```

## Editing the Profile

To modify profile pages, edit the .md files in the _pages directory. The main homepage can be edited via about.md. Formatting parameters can be adjusted in the _config.yml file.

## CI & CD

To avoid CI errors, make sure that all hyperlinks on the site are accessible. If certain links need to be ignored during link checks, add them to the .lycheeignore file.

Before committing changes, format the Markdown files by running:

```sh
npx prettier . --write
```

