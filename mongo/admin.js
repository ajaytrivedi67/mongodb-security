db.getSiblingDB('admin').createRole({
  role: 'cn=DBAdmin,ou=Groups,dc=simagix,dc=local',
  privileges: [],
  roles: [ 'root' ] });
db.getSiblingDB('admin').createRole({
  role: 'cn=Reporting,ou=Groups,dc=simagix,dc=local',
  privileges: [],
  roles: [ {role: 'readAnyDatabase', db: 'admin'} ] });
db.getSiblingDB('testdb').values.insertMany([{_id:1,v:1},{_id:2,v:2},{_id:3,v:3}])
