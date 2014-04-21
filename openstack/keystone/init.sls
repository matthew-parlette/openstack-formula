keystone:
  service:
    - running
    - enable: True
    - require:
      - pkg: keystone
      - service: mysql-server
      - mysql_database: keystone-db
    - watch:
      # - cmd: keystone-db-init
      - file: /etc/keystone
      # - service: mysql
      # - mysql_database: keystone
      # - mysql_user: keystone
      # - mysql_grants: keystone
  pkg:
    - installed

/etc/keystone:
  file:
    - recurse
    - source: salt://openstack/keystone/files
    - template: jinja
    - require:
      - pkg: keystone
