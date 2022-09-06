db.getSiblingDB('admin').createUser({
  user: 'admin',
  pwd: 'secret',
  roles: [ 'root' ]});
db.getSiblingDB('admin').createRole({
  role: 'cn=DBAdmin,ou=Groups,dc=simagix,dc=local',
  privileges: [],
  roles: [ 'root' ] });
db.getSiblingDB('admin').createRole({
  role: 'cn=Reporting,ou=Groups,dc=simagix,dc=local',
  privileges: [],
  roles: [ {role: 'readAnyDatabase', db: 'admin'} ] });
db.getSiblingDB('admin').shutdownServer();
