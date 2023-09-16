set -a;. ./eventer.env;set +a
rdbg --open -n -c -- rails s -b 'ssl://0:3000?key=localhost.key&cert=localhost.crt'
