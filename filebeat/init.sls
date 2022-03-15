
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

{%- for output_module_name, output_module in filebeat.output.items() %}

{%- if ssl in output_module %}

{%- if certificate in output_module.ssl %}
{{ filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.crt' }}:
  file.managed:
    - contents: |
        {{ config_content.output[output_module_name].ssl.certificate | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ conf.config_path }}
{%- set config_content.output[output_module_name].ssl.certificate = filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.crt' %}
{%- endif %}

{%- if key in output_module.ssl %}
{{ filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.key' }}:
  file.managed:
    - contents: |
        {{ config_content.output[output_module_name].ssl.key | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ conf.config_path }}
{%- set config_content.output[output_module_name].ssl.key = filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.key' %}
{%- endif %}

{%- if certificate_authorities in output_module.ssl %}
{{ filebeat.config_path ~ 'certs/ca.crt' }}:
  file.managed:
    - contents: |
        {{ config_content.output[output_module_name].ssl.certificate_authorities | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ conf.config_path }}
{%- set config_content.output[output_module_name].ssl.certificate_authorities = filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-ca.crt' %}
{%- endif %}

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
      - filebeat_install
    - watch:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}

{%- else -%}

# Do uninstallation and cleanup stuff

{%- endif %}

{%- endif %}