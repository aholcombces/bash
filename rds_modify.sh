#!/bin/bash
# written by: atholcomb
# rds_modify.sh
# calls awscli - removes old database instance and restores a new database instance from a specified snapshot

echo -n "What is the name of the database (db-identifier): "
read dbname

# Check database status
check_db_instance=$(aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus")

if [[ $check_db_instance == $check_db_instance ]]; then
    echo "Database is up and running"
    aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus"
fi

# Check snapshot info
echo "Lastest snapshot info:"
aws rds describe-db-snapshots --db-snapshot-identifier testsnapshot | grep -i "InstanceCreateTime"
aws rds describe-db-snapshots --db-snapshot-identifier testsnapshot | grep -i  "SnapshotCreateTime"
aws rds describe-db-snapshots --db-snapshot-identifier testsnapshot | grep -i  "DBInstanceIdentifier"
aws rds describe-db-snapshots --db-snapshot-identifier testsnapshot | grep -i  "DBSnapshotIdentifier"
aws rds describe-db-snapshots --db-snapshot-identifier testsnapshot | grep -i "Engine"
aws rds describe-db-snapshots --db-snapshot-identifier testsnapshot | grep -i "Status"

# Create database snapshot
echo
echo -n "Would you like to create a database snapshot [y/n]: "
read createsnapshot
if [[ $createsnapshot == "y" ]]; then
    echo -n "What will be the name of the new snapshot: "
    read snapshotname
    echo "Creating snapshot"
    aws rds create-db-snapshot --db-instance-identifier $dbname --db-snapshot-identifier $snapshotname
else
    echo "Snapshot aborted"
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

# Check if database instance has been removed from Console
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

# Restore database from snapshot
echo
echo -n "Would you like to restore and create new database from snapshot [y/n]: "
read restoredb
if [[ $restoredb == "y" ]]; then
    echo -n "What is the name of the snapshot: "
    read snapshot
    echo -n "What will be the name of the new database: "
    read newdbname
    echo "New database $newdbname will be created from snapshot $snapshot"
    aws rds restore-db-instance-from-db-snapshot --db-snapshot-identifier $snapshot --db-instance-identifier $newdbname | grep -i "DBInstanceStatus"
else
    echo "Restore from snapshot aborted"
fi
