include:
  - mysql.python
  - rabbitmq
  - openstack.mysql
  # - openstack.nova
  - openstack.glance
  - openstack.keystone
  # - openstack.horizon

setup-rabbit:
  cmd:
    - run
    - name: rabbitmqctl change_password guest {{ salt['pillar.get']('openstack:password:rabbitmq', 'guest') }}
    - require:
      - pkg: rabbitmq-server
      - service: rabbitmq-server

# mysql-install-db:
  # cmd:
    # - run
    # - name: mysql_install_db
    # - unless: 
    # - require:
      # - pkg: mysql
      # - service: mysqld

# mysql-secure-installation:
  # cmd:
    # - run
    # - name: mysql_secure_installation
    # - watch:
      # - cmd: mysql-install-db

