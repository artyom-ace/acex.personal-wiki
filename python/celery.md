### default run command for worker
env.COMMAND_WORKER = '["celery", "-A", "config", "worker", "-c 4", "--loglevel=info", "--max-tasks-per-child=1"]'
### debug run command for worker
env.COMMAND_WORKER = '["celery", "-A", "config", "worker", "-c 4", "--loglevel=debug", "--max-tasks-per-child=1", "--task-events",  "--events"]'


### debug on celery broker RabbitMQ in console
##### connections count (-c - count; -v "user" - exclude header row)
rabbitmqctl list_connections | grep -c -v "user"
##### hosts count
rabbitmqctl list_connections | awk 'NR>1 {print $2}' | cut -d: -f1 | sort -u | wc -l
##### channels count
rabbitmqctl list_channels | grep -c -v "user"
#### all in one
printf "Подключения: %s\nУникальные IP: %s\nКаналы: %s\n"   $(rabbitmqctl list_connections | grep -c -v "user")   $(rabbitmqctl list_connections | awk 'NR>1 {print $2}' | cut -d: -f1 | sort -u | wc -l)   $(rabbitmqctl list_channels | grep -c -v "user")

#### rabbitmqctl bedug
rabbitmqctl list_vhost_limits
rabbitmqctl list_vhosts
rabbitmqctl list_users
rabbitmqctl list_user_limits --user dhqueue --global
rabbitmqctl environment | grep -E 'channel_max|connection_max'
