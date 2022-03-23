
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

{%- set config_content = namespace(root = {'filebeat' : {}}) %}

{%- if filebeat.inputs is defined %}
{%- do config_content.root.filebeat.update({'inputs' : filebeat.inputs}) %}
{%- endif %}

{%- if filebeat.config_modules is defined %}
{%- do config_content.root.filebeat.update({'config' : {'modules' : filebeat.config_modules}}) %}
{%- endif %}

{%- if filebeat.http is defined %}
{%- do config_content.root.update({'http' : filebeat.http}) %}
{%- endif %}

{%- if filebeat.output is defined %}
{%- do config_content.root.update({'output' : filebeat.output}) %}

{%- for output_module_name, output_module in filebeat.output.items() %}

{%- if output_module.ssl is defined %}
{{ filebeat.config_path ~ 'certs/' }}:
  file.directory:
    - user: root
    - group: root
    - mode: 600
    - makedirs: True

{%- if output_module.ssl.certificate is defined %}
{{ filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.crt' }}:
  file.managed:
    - contents: |
        {{ output_module.ssl.certificate | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ filebeat.service_name }}
{%- do config_content.root.output[output_module_name].ssl.update({'certificate' : filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.crt'}) %}
{%- endif %}

{%- if output_module.ssl.key is defined %}
{{ filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.key' }}:
  file.managed:
    - contents: |
        {{ output_module.ssl.key | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ filebeat.service_name }}
{%- do config_content.root.output[output_module_name].ssl.update({'key' : filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-server.key'}) %}
{%- endif %}

{%- if output_module.ssl.certificate_authorities is defined %}
{{ filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-ca.crt' }}:
  file.managed:
    - contents: |
        {{ output_module.ssl.certificate_authorities | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ filebeat.service_name }}
{%- do config_content.root.output[output_module_name].ssl.update({'certificate_authorities' : filebeat.config_path ~ 'certs/' ~ output_module_name ~ '-ca.crt'}) %}
{%- endif %}

{%- endif %}
{%- endfor %}
{%- endif %}

{{ filebeat.config_path ~ 'filebeat.yml' }}:
  file.serialize:
    - dataset: {{ config_content.root | json }}
    - serializer: yaml
    - show_changes: true
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: {{ filebeat.package_name }}

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