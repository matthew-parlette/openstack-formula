keystone:
  service:
    - running
    - enable: True
    - require:
      - pkg: keystone
      - service: mysql-server
      - mysql_database: keystone-db
    - watch:
      - file: /etc/keystone
  pkg:
    - installed

keystone-db-sync:
  cmd:
    - run
    - name: keystone-manage db_sync

/etc/keystone:
  file:
    - recurse
    - source: salt://openstack/keystone/files
    - template: jinja
    - require:
      - pkg: keystone

{% set admin_token = salt['pillar.get']('openstack:token:admin','') %}
{% set os_endpoint = "http://localhost:35357/v2.0" %}
{% set keystone_cmd = "keystone --os-token " ~ admin_token  ~ " --os-endpoint " ~ os_endpoint %}
{% for tenant,description in salt['pillar.get']('openstack:tenant',{}).iteritems() %}
keystone-tenant-{{ tenant }}:
  cmd:
    - run
    - name: {{ keystone_cmd }} tenant-create --name={{ tenant }} --description='{{ description }}'
    - unless: {{ keystone_cmd }} tenant-get {{ tenant }}
    - require:
      - service: keystone
{% endfor %}

{% for user,password in salt['pillar.get']('openstack:user',{}).iteritems() %}
keystone-user-{{ user }}:
  cmd:
    - run
    - name: {{ keystone_cmd }} user-create --name={{ user }} --pass={{ password }}
    - unless: {{ keystone_cmd }} user-get {{ user }}
    - require:
      - service: keystone
{% endfor %}

{% for role in salt['pillar.get']('openstack:role',[]) %}
keystone-role-{{ role }}:
  cmd:
    - run
    - name: {{ keystone_cmd }} role-create --name={{ role }}
    - unless: {{ keystone_cmd }} role-get {{ role }}
    - require:
      - service: keystone
{% endfor %}

{% for tenant in salt['pillar.get']('openstack:user-role',[]) %}
  {% for role in salt['pillar.get']('openstack:user-role:' ~ tenant,[]) %}
    {% for user in salt['pillar.get']('openstack:user-role:' ~ tenant ~ ':' ~ role,[]) %}
keystone-{{ tenant }}-{{ user }}-{{ role }}-assignment:
  cmd:
    - run
    - name: {{ keystone_cmd }} user-role-add --user={{ user }} --tenant={{ tenant }} --role={{ role }}
    - unless: {{ keystone_cmd }} user-role-list | grep {{ user }}
    - require:
      - service: keystone
      - cmd: keystone-tenant-{{ tenant }}
      - cmd: keystone-user-{{ user }}
      - cmd: keystone-role-{{ role }}
    {% endfor %}
  {% endfor %}
{% endfor %}

{% for service in salt['pillar.get']('openstack:service',[]) %}
{% set type = salt['pillar.get']('openstack:service:' ~ service ~ ':type','') %}
{% set description = salt['pillar.get']('openstack:service:' ~ service ~ ':description','') %}
keystone-service-{{ service }}:
  cmd:
    - run
    - name: {{ keystone_cmd }} service-create --name={{ service }} --type={{ type }} --description='{{ description }}'
    - unless: {{ keystone_cmd }} service-get {{ service }}
    - require:
      - service: keystone

{% set adminurl = salt['pillar.get']('openstack:service:' ~ service ~ ':endpoint:adminurl','') %}
{% set internalurl = salt['pillar.get']('openstack:service:' ~ service ~ ':endpoint:internalurl','') %}
{% set publicurl = salt['pillar.get']('openstack:service:' ~ service ~ ':endpoint:publicurl','') %}

keystone-endpoint-{{ service }}:
  cmd:
    - run
    - name: {{ keystone_cmd }} endpoint-create --service-id=`{{ keystone_cmd }} service-get {{ service }} | grep ' id ' | awk '{print $4}'` --adminurl={{ adminurl }} --internalurl={{ internalurl }} --publicurl={{ publicurl }}
    - unless: {{ keystone_cmd }} endpoint-get --service {{ type }}
    - require:
      - service: keystone
      - cmd: keystone-service-{{ service }}
{% endfor %}
