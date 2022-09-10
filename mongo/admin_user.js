db.getSiblingDB('admin').createUser({
  user: 'admin',
  pwd: 'secret',
  roles: [ 'root' ]});
