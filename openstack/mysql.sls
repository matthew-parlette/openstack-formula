mysql-server:
  pkg:
    - installed
  file.sed:
    - name: /etc/mysql/my.cnf
    - before: '127.0.0.1'
    - after: '0.0.0.0'
    - limit: '^bind-address'
    - require:
      - pkg: mysql-server
  service:
    - running
    - name: mysql
    - restart: True
    - enable: True
    - require:
      - pkg: mysql-server
    - watch:
      - file: /etc/mysql/my.cnf

{% for user in ['keystone','glance'] %}
{{ user }}-db:
  mysql_user.present:
    - name: {{ user }}
    - host: "%"
    - password: {{ pillar['openstack']['database'][user] }}
    - require:
      - pkg: mysql-server
      - file: /etc/mysql/my.cnf
    - watch:
      - service: mysql-server
  mysql_database:
    - present
    - name: {{ user }}
    - charset: utf8
    - collate: utf8_general_ci
    - require:
      - pkg: mysql-server
      - file: /etc/mysql/my.cnf
    - watch:
      - service: mysql-server
  mysql_grants.present:
    - grant: all
    - database: "{{ user }}.*"
    - user: {{ user }}
    - require:
      - pkg: mysql-server
      - file: /etc/mysql/my.cnf
      - mysql_database: {{ user }}-db
    - watch:
      - service: mysql-server

{{ user }}-grant-wildcard:
  cmd.run:
    - name: mysql -e "GRANT ALL ON {{ user }}.* TO '{{ user }}'@'%' IDENTIFIED BY '{{ pillar['openstack']['database'][user] }}';"
    - unless: mysql -e "select Host,User from user Where user='{{ user }}' AND  host='%';" | grep {{ user }}
    - require:
      - pkg: mysql-server
      - file: /etc/mysql/my.cnf
    - watch:
      - cmd: {{ user }}-grant-star
      - cmd: {{ user }}-grant-localhost

{{ user }}-grant-localhost:
  cmd.run:
    - name: mysql -e "GRANT ALL ON {{ user }}.* TO '{{ user }}'@'localhost' IDENTIFIED BY '{{ pillar['openstack']['database'][user] }}';"
    - unless: mysql -e "select Host,User from user Where user='{{ user }}' AND  host='localhost';" | grep {{ user }}
    - require:
      - pkg: mysql-server
      - file: /etc/mysql/my.cnf
    - watch:
      - cmd: {{ user }}-grant-star

{{ user }}-grant-star:
  cmd.run:
    - name: mysql -e "GRANT ALL ON {{ user }}.* TO '{{ user }}'@'*' IDENTIFIED BY '{{ pillar['openstack']['database'][user] }}';"
    - unless: mysql -e "select Host,User from user Where user='{{ user }}' AND  host='*';" | grep {{ user }}
    - require:
      - pkg: mysql-server
      - file: /etc/mysql/my.cnf
    - watch:
      - mysql_database: {{ user }}-db

{% endfor %}
