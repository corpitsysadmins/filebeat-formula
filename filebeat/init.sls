
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
      - file: {{ conf.config_path }}
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
      - file: {{ conf.config_path }}
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
      - file: {{ conf.config_path }}
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

{% set ssl_cert = salt['pillar.get']('filebeat:logstash:tls:ssl_cert', 'salt://filebeat/files/ca.pem') %}
{% set ssl_cert_path = salt['pillar.get']('filebeat:logstash:tls:ssl_cert_path') %}
{% set managed_cert = salt['pillar.get']('filebeat:logstash:tls:managed_cert', True) %}
{% set ssl_key = salt['pillar.get']('filebeat:logstash:tls:ssl_key') %}
{% set ssl_key_path = salt['pillar.get']('filebeat:logstash:tls:ssl_key_path') %}
{% set ssl_ca = salt['pillar.get']('filebeat:logstash:tls:ssl_ca') %}
{% set ssl_ca_path = salt['pillar.get']('filebeat:logstash:tls:ssl_ca_path') %}

filebeat.service:
  service.running:
    - name: filebeat
    - enable: true
    - require:
      - pkg: filebeat
    - watch:
      - file: /etc/filebeat/filebeat.yml

{%- else -%}

# Do uninstallation and cleanup stuff

{%- endif %}

{%- endif %}