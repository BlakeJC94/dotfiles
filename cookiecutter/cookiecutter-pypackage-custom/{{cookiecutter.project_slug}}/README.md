{% set is_open_source = cookiecutter.open_source_license != 'Not open source' -%}

# {{ cookiecutter.project_name }}

{% if is_open_source %}

[![GitHub license](https://img.shields.io/github/license/Naereen/StrapDown.js.svg)](https://github.com/{{ cookiecutter.github_username }}/{{ cookiecutter.project_slug }}/master/LICENSE)

{%- endif %}

{{ cookiecutter.project_short_description }}

{% if is_open_source %}
* Free software: {{ cookiecutter.open_source_license }}
{% endif %}

## Features

* TODO

## Usage

```

```

## Installation

Installing with pipx from Github::

```
pipx install git+https://www.github.com/{{ cookiecutter.github_username }}/{{ cookiecutter.project_slug }}
```

Installing with pip from Github::

```
pip install git+https://www.github.com/{{ cookiecutter.github_username }}/{{ cookiecutter.project_slug }}
```

## Credits

This project was created with [Cookiecutter](https://github.com/cookiecutter/cookiecutter).
