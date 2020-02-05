#!/bin/bash
# written by: atholcomb
# rds_modify.sh
# calls awscli - removes old database instance and restores a new instance from a specified snapshot

echo -n "What is the name of the database (db-identifier): "
read dbname

# Check database status
check_db_instance=$(aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus")

#if [[ $check_db_instance == `aws rds describe-db-instances --db-instance-identifier database2 | grep -i "DBInstanceStatus"` ]]; then
if [[ $check_db_instance == $check_db_instance ]]; then
    echo "Database is up and running"
    aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus"
fi

# Delete database instance #| --final-db-snapshot-identifier <value>
echo
echo -n "Would you like to delete current database [y/n]: "
read deldatabase
if [[ $deldatabase == "y" ]]; then
    echo "Database will be deleted"
    aws rds delete-db-instance --db-instance-identifier $dbname --skip-final-snapshot | grep -i "DBInstanceStatus"
else
    echo "Database deletion aborted"
fi

echo
echo "Checking if database has been removed..."
echo "This process can take a while. Please wait."
while :
do
    dboutput=$(aws rds describe-db-instances --query 'DBInstances[*].[DBName,DBInstanceIdentifier]' --filters Name=db-instance-id,Values=$dbname --output text)
    if  [ "$dboutput" == '' ]; then 
        echo "Database has been removed."
        break
    fi 
done

## Restore database from snapshot
echo
echo -n "Would you like to restore and create new database from snapshot [y/n]: "
read restoredb
if [[ $restoredb == "y" ]]; then
    echo -n "What is the name of the snapshot: "
    read snapshot
    echo -n "What will be the name of the new database: "
    read newdbname
    echo "Snapshot will be created"
    aws rds restore-db-instance-from-db-snapshot --db-snapshot-identifier $snapshot --db-instance-identifier $newdbname | grep -i "DBInstanceStatus"
else
    echo "Restore from snapshot aborted"
fi
