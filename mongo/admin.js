db.getSisterDB('admin').createUser({
  user: 'admin',
  pwd: 'secret',
  roles: [ 'root' ]});
db.getSisterDB('admin').createRole({
  role: 'cn=DBAdmin,ou=Groups,dc=simagix,dc=local',
  privileges: [],
  roles: [ 'root' ] });
db.getSisterDB('admin').createRole({
  role: 'cn=Reporting,ou=Groups,dc=simagix,dc=local',
  privileges: [],
  roles: [ {role: 'readWriteAnyDatabase', db: 'admin'} ] });
db.getSisterDB('admin').shutdownServer();
