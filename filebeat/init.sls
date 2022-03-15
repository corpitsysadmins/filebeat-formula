
{% set default_sources = {'module' : 'filebeat', 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{% from "./defaults/load_config.jinja" import config as filebeat with context %}

{% if filebeat.use is defined -%}

{% if filebeat.use | to_bool -%}

# Do installation and configuration stuff

{%- else -%}

# Do uninstallation and cleanup stuff

{%- endif %}

{%- endif %}