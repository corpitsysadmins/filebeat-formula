
{% set default_sources = {'module' : 'filebeat', 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "./defaults/load_config.jinja" import config as filebeat with context %}

{% if filebeat.use is defined -%}

{% if filebeat.use | to_bool -%}

{% if salt['grains.get']('os_family') == 'Debian' %}
filebeat_repo:
  pkgrepo.managed:
    - name: deb https://artifacts.elastic.co/packages/8.x/apt stable main
    - file: /etc/apt/sources.list.d/elastic-8.x.list
    - gpgcheck: 1
    - key_url: https://packages.elastic.co/GPG-KEY-elasticsearch
    - require_in:
      - pkg: filebeat.install
    - watch_in:
      - pkg: filebeat.install
      
{% elif salt['grains.get']('os_family') == 'RedHat' %}
filebeat_repo:
  pkgrepo.managed:
    - name: elastic-8.x
    - humanname: Elasticsearch repository for 8.x packages
    - baseurl: https://artifacts.elastic.co/packages/8.x/yum
    - gpgcheck: 1
    - gpgkey: https://packages.elastic.co/GPG-KEY-elasticsearch
    - require_in:
      - pkg: filebeat.install
    - watch_in:
      - pkg: filebeat.install
{% endif %}

filebeat.install:
  pkg.installed:
    - name: filebeat
    - version: '8*'

{% set ssl_cert = salt['pillar.get']('filebeat:logstash:tls:ssl_cert', 'salt://filebeat/files/ca.pem') %}
{% set ssl_cert_path = salt['pillar.get']('filebeat:logstash:tls:ssl_cert_path') %}
{% set managed_cert = salt['pillar.get']('filebeat:logstash:tls:managed_cert', True) %}
{% set ssl_key = salt['pillar.get']('filebeat:logstash:tls:ssl_key') %}
{% set ssl_key_path = salt['pillar.get']('filebeat:logstash:tls:ssl_key_path') %}
{% set ssl_ca = salt['pillar.get']('filebeat:logstash:tls:ssl_ca') %}
{% set ssl_ca_path = salt['pillar.get']('filebeat:logstash:tls:ssl_ca_path') %}
{% if salt['pillar.get']('filebeat:logstash:tls:enabled', False) and ssl_cert and ssl_cert_path and managed_cert %}
{{ ssl_cert_path }}:
  file.managed:
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - contents_pillar: filebeat:logstash:tls:ssl_cert
    - watch_in:
      - filebeat.config
{% endif %}
{% if salt['pillar.get']('filebeat:logstash:tls:enabled', False) and ssl_key and ssl_key_path and managed_cert %}
{{ ssl_key_path }}:
  file.managed:
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - contents_pillar: filebeat:logstash:tls:ssl_key
    - watch_in:
      - filebeat.config
{% endif %}
{% if salt['pillar.get']('filebeat:logstash:tls:enabled', False) and ssl_ca and ssl_ca_path and managed_cert %}
{{ ssl_ca_path }}:
  file.managed:
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - contents_pillar: filebeat:logstash:tls:ssl_ca
    - watch_in:
      - filebeat.config
{% endif %}
filebeat.config:
  file.managed:
    - name: {{ conf.config_path }}
    - source: {{ conf.config_source }}
    - template: jinja
    - user: root
    - group: root
    - mode: 644

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