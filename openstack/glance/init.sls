glance:
  service:
    - running
    - enable: True
    - names:
      - glance-api
      - glance-registry
    - require:
      - pkg: glance
      - service: mysql-server
      - mysql_database: glance-db
    - watch:
      - file: /etc/glance
      - cmd: keystone-endpoint-glance
  pkg:
    - installed
    - names:
      - glance
      - glance-api
      - glance-common
      - glance-registry
      - python-glanceclient

glance-storage:
  file.directory:
    - name: {{ salt['pillar.get']('openstack:glance:api:filesystem_store_datadir', '/var/lib/glance/images') }}
    - user: glance
    - group: glance
    - mode: 754
    - recurse:
      - user
      - group

glance-db-sync:
  cmd:
    - run
    - name: glance-manage db_sync
    - require:
      - mysql_database: glance-db
      - file: glance-storage
      - file: /etc/glance

/etc/glance:
  file:
    - recurse
    - source: salt://openstack/glance/files
    - template: jinja
    - require:
      - pkg: glance
