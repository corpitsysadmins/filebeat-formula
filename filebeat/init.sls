
{% set default_sources = {'module' : 'filebeat', 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "./defaults/load_config.jinja" import config as filebeat with context %}

{% if filebeat.use is defined -%}

{% if filebeat.use | to_bool -%}

filebeat_repo:
  pkgrepo.managed: {{ filebeat.repo_info | json }}

filebeat_install:
  pkg.installed:
    - name: {{ filebeat.package_name }}
    - version: {{ filebeat.install_version }}
  require:
    - filebeat_repo
  watch:
    - filebeat_repo

{%- set config_content = namespace(filebeat = {'inputs' : filebeat.inputs, 'config' : {'modules' : filebeat.config_modules}}, output = filebeat.output) %}

{%- for output_module_name, output_module in filebeat['output'].items() %}

{%- if 'ssl' in output_module %}

{%- endif %}
{%- endfor %}

{{ filebeat.config_path ~ 'filebeat.yml' }}
  file.serialize:
    - dataset: {{ config_content | json }}
    - serializer: yaml
    - user: root
    - group: root
    - mode: 644
    - require:
      - filebeat_install

filebeat_service:
  service.running:
    - name: {{ filebeat.service_name }}
    - enable: true
    - require:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}

{%- else -%}

# Do uninstallation and cleanup stuff

{%- endif %}

{%- endif %}