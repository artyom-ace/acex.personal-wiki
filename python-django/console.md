### new migration
python ./app/manage.py makemigrations ms_migrations --empty


python ./src/manage.py migrate
	python ./src/manage.py runserver
	python ./src/manage.py runserver_plus --print-sql   - детальный вывод sql логов