#!/usr/bin/env bash

RED='\033[0;31m'

{% if cookiecutter.git == "y" %}
echo -e "\n"
git init
echo -e "\n"
{% else %}
printf "${RED}No Git Repo"
{% endif %}

{% if cookiecutter.github == "y" %}
echo "Setup Github Repo:"
echo -e "\n"
gh repo create '{{ cookiecutter.project_slug }}' -d '{{ cookiecutter.project_short_description }}'
echo -e "\n"
{% else %}
printf "${RED}No Github Repo"
echo -e "\n"
{% endif %}
