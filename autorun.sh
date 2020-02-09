#!/bin/bash
# written by: atholcomb
# autorun.sh
# calls awscli - removes old database instance and restores a new database instance from a specified snapshot

# save output in cron job to output file
# /path/to/your/script.sh > output.txt

echo "Date ran: $(date)"

dbname=$1
latestsnapshot=$(aws rds describe-db-snapshots --db-instance-identifier=$dbname --query="reverse(sort_by(DBSnapshots, &SnapshotCreateTime))[0] | DBSnapshotIdentifier" --output text)
#latestsnapshot=$(aws rds describe-db-snapshots --db-instance-identifier=$dbname --query="reverse(sort_by(DBSnapshots, &SnapshotCreateTime))[0] | DBSnapshotArn" --output text)

# Check database status
check_db_instance=$(aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus")

#if [[ $check_db_instance == $check_db_instance ]]; then
if [[ -n "$check_db_instance" ]]; then
    echo "Database is up and running"
    aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus"
else
    echo "No database $dbname"
    exit 1
fi

# Check snapshot info
echo
echo "Lastest snapshot info:"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "InstanceCreateTime"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "SnapshotCreateTime"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "DBInstanceIdentifier"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "DBSnapshotIdentifier"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "Engine"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "Status"

# Delete database instance #| --final-db-snapshot-identifier <value>
echo
echo "$dbname will be deleted"
aws rds delete-db-instance --db-instance-identifier $dbname --skip-final-snapshot | grep -i "DBInstanceStatus"

# Check if database instance has been removed from Console
echo
echo "Checking if database has been removed..."
echo "This process can take a while. Please wait."
echo
while :
do
    dboutput=$(aws rds describe-db-instances --query 'DBInstances[*].[DBName,DBInstanceIdentifier]' --filters Name=db-instance-id,Values=$dbname --output text)
    if  [ "$dboutput" == '' ]; then 
        echo "Database has been removed."
        break
    fi 
done

# Restore database from snapshot
# --db-subnet-group-name
# --vpc-security-group-ids
# --availability-zone us-east-2b
echo
echo "database $dbname will be created from snapshot $latestsnapshot"
aws rds restore-db-instance-from-db-snapshot --db-snapshot-identifier $latestsnapshot --db-instance-identifier $dbname | grep -i "DBInstanceStatus"
echo

# Check if new database is available
echo "Checking if $dbname is available..."
echo "This process can take a while. Please wait."
while :
do
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus")
    dbavailable=$(aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus" | grep -i "available")
    if [[ "$dbstatus" == $dbavailable ]]; then
        echo "Database $dbname is available"
        break
    fi
done

# Stop new database instance (if aim is to save cost in non-prod)
#echo
#echo "Stopping database $dbname ..."
#aws rds stop-db-instance --db-instance-identifier $dbname | grep -i "DBInstanceStatus"
