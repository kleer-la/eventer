set -a;. ./eventer.env;set +a
rails s -b 'ssl://0:3000?key=localhost.key&cert=localhost.crt'
