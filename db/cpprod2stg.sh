# run from project route folder. ie: ./db/migrate-stg.sh
heroku pg:backups capture --app keventer-test
heroku pg:copy keventer::DATABASE_URL DATABASE_URL --app keventer-test --confirm keventer-test
heroku run rake jobs:clear --app keventer-test
heroku ps:restart web1 --app keventer-test
