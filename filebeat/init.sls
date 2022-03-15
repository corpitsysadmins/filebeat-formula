
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
    - pkgrepo: filebeat_repo
  watch:
    - pkgrepo: filebeat_repo

{%- set config_content = namespace(filebeat = {'inputs' : filebeat.inputs, 'config' : {'modules' : filebeat.config_modules}}, output = filebeat.output) %}

{{ filebeat.config_path ~ 'filebeat.yml' }}
  file.serialize:
    - dataset: {{ config_content | json }}
    - serializer: yaml
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: {{ filebeat.package_name }}

{%- else -%}

# Do uninstallation and cleanup stuff

{%- endif %}

{%- endif %}