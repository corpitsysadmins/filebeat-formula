
{% set default_sources = {'module' : 'filebeat', 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "./defaults/load_config.jinja" import config as filebeat with context %}

{% if filebeat.use is defined -%}

{% if filebeat.use | to_bool -%}

filebeat_repo:
  pkgrepo.managed:
{%- for key, value in filebeat.repo_info.items() %}
    - {{ key }}: {{ value }}
{%- endfor %}

filebeat_install:
  pkg.installed:
    - name: {{ filebeat.package_name }}
    - version: {{ filebeat.install_version }}
  require:
    - filebeat_repo
  watch:
    - filebeat_repo

{%- else -%}

# Do uninstallation and cleanup stuff

{%- endif %}

{%- endif %}