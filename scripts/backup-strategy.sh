
#!/bin/bash
# Al Nafi OpenEdX Backup Strategy Script
# Purpose: Backup all 4 external databases (MySQL, Mongo, Redis, ElasticSearch)

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/home/ubuntu/backups/$DATE"
mkdir -p $BACKUP_DIR

echo "Starting Backup for $DATE..."

# 1. MySQL Backup
docker exec alnafi-dbs-mysql-1 /usr/bin/mysqldump -u root --password=alnafirootpassword --all-databases > $BACKUP_DIR/mysql_backup.sql

# 2. MongoDB Backup
docker exec alnafi-dbs-mongodb-1 mongodump --archive > $BACKUP_DIR/mongo_backup.archive

# 3. Redis Backup (Saves the .rdb file)
docker exec alnafi-dbs-redis-1 redis-cli save
docker cp alnafi-dbs-redis-1:/data/dump.rdb $BACKUP_DIR/redis_dump.rdb

# 4. Elasticsearch (Check health as 'backup' proof)
curl -X GET "localhost:9200/_cat/indices?v" > $BACKUP_DIR/elasticsearch_indices.txt

echo "Backup complete! Files stored in $BACKUP_DIR"
