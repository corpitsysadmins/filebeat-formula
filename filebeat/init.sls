
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

{{ filebeat.config_path ~ 'certs/server.crt' }}:
  file.managed:
    - contents: |
        {{ filebeat.ssl_cert | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ conf.config_path }}

{{ filebeat.config_path ~ 'certs/server.key' }}:
  file.managed:
    - contents: |
        {{ filebeat.ssl_key | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ conf.config_path }}

{{ filebeat.config_path ~ 'certs/ca.crt' }}:
  file.managed:
    - contents: |
        {{ filebeat.ssl_ca | indent(8) }}
    - mode: 600
    - user: root
    - group: root
    - require_in:
      - file: {{ filebeat.config_path ~ 'filebeat.yml' }}
    - watch_in:
      - service: {{ conf.config_path }}

{%- set config_content = {'filebeat' : {'inputs' : filebeat.inputs, 'config' : {'modules' : filebeat.config_modules}}, 'output' : filebeat.output} %}
{{ filebeat.config_path ~ 'filebeat.yml' }}
  file.serialize:
    - dataset: {{ config_content | json }}
    - serializer: yaml
    - user: root
    - group: root
    - mode: 644
    - require:
      - filebeat_install

filebeat.service:
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