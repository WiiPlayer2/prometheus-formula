# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import prometheus as p with context %}
{%- set sls_config_users = tplroot ~ '.config.users' %}

{%- set states = [] %}
{%- set name = 'node_exporter' %}
{%- if name in p.wanted.component and 'service' in p.pkg.component[name] %}

{%- for k, v in p.get('exporters', {}).get(name, {}).get('textfile_collectors', {}).items() %}
{%-     if v.get('enable', False) %}
{%-         if v.get('remove', False) %}
{%-             set state = ".{}.clean".format(k) %}
{%-         else %}
{%-             set state = ".{}.install".format(k) %}
{%-         endif %}
{%-         do states.append(state) %}
{%-     endif %}
{%- endfor %}

    {%- if 'collector.textfile.directory' in p.pkg.component[name]['service']['args'] %}
prometheus-exporters-{{ name }}-collector-textfile-dir:
  file.directory:
    - name: {{ p.pkg.component[name]['service']['args']['collector.textfile.directory'] }}
        {%- if grains.os != 'Windows' %}
    - mode: 755
    - user: {{ name }}
    - group: {{ name }}
        {%- endif %}
    - makedirs: True
    - require:
      - user: prometheus-config-users-install-{{ name }}-user-present
      - group: prometheus-config-users-install-{{ name }}-group-present
    - require_in:
{%-     for state in states %}
      - sls: {{ tplroot }}.exporters.{{ name }}.textfile_collectors{{ state }}
{%-     endfor %}
    {%- endif %}

    {%- if states|length > 0 and p.exporters[name]['textfile_collectors_dependencies'] %}
prometheus-exporters-{{ name }}-textfile-dependencies:
  pkg.installed:
    - pkgs: {{ p.exporters[name]['textfile_collectors_dependencies'] }}
    - require_in:
{%-     for state in states %}
      - sls: {{ tplroot }}.exporters.{{ name }}.textfile_collectors{{ state }}
{%-     endfor %}

    {%- endif %}
{%- endif %}

include:
  - {{ sls_config_users }}
{%- for state in states %}
  - {{ state }}
{%  endfor %}
