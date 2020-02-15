#!/bin/bash
# written by: atholcomb
# leapdb_modify.sh
# calls awscli - removes old database instance and restores a new database instance from a specified snapshot

# Configure $HOME variable for aws config file to be read in
export HOME=/root

# Measure the time the script takes to run -- look at $duration below
SECONDS=0

echo "Date ran: $(date)"
echo

dbname="ces-leapdb"
newdb=$1
latestsnapshot=$(aws rds describe-db-snapshots --db-instance-identifier=$dbname --query="reverse(sort_by(DBSnapshots, &SnapshotCreateTime))[0] | DBSnapshotIdentifier" --output text)

# Check database status
echo "$dbname database status..."
aws rds describe-db-instances --db-instance-identifier $dbname | grep -i "DBInstanceStatus"
echo "$newdb database status..."
aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus"

# Check snapshot info
echo
echo "Lastest snapshot info for $dbname:"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "InstanceCreateTime"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "SnapshotCreateTime"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "DBInstanceIdentifier"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "DBSnapshotIdentifier"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "Engine"
aws rds describe-db-snapshots --db-snapshot-identifier $latestsnapshot | grep -i "Status"

# Delete database instance #| --final-db-snapshot-identifier <value>
echo
echo "Deleting $newdb so restore can begin..."
aws rds delete-db-instance --db-instance-identifier $newdb --skip-final-snapshot | grep -i "DBInstanceStatus"

# Check if database instance has been removed from Console
echo
echo "Checking if database has been removed..."
echo "This process can take a while. Please wait."
echo
while :
do
    dboutput=$(aws rds describe-db-instances --query 'DBInstances[*].[DBName,DBInstanceIdentifier]' --filters Name=db-instance-id,Values=$newdb --output text)
    if  [ "$dboutput" == '' ]; then 
        echo "--------------------------------------"
        echo "$newdb has been removed."
        echo "--------------------------------------"
        break
    fi 
done

# Restore database from snapshot
echo
echo "Creating ces-leapdb-test from restored snapshot id: $latestsnapshot"
aws rds restore-db-instance-from-db-snapshot --db-snapshot-identifier $latestsnapshot --db-subnet-group-name ces-prd-stack-dbsubnetgroup-f72doe140v1l --vpc-security-group-ids sg-03b91652619d09223 sg-04dd1ad63f4b60a67 --db-instance-class db.t2.medium --db-instance-identifier $newdb | grep -i "DBInstanceStatus"
echo

# Check if new database is available
echo "Checking if $newdb is available and online..."
echo "This process can take a while. Please wait."
echo
while :
do
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus")
    dbavailable=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus" | grep -i "available")
    if [[ "$dbstatus" == $dbavailable ]]; then
        echo "--------------------------------"
        echo "$newdb is available"
        echo "--------------------------------"
        break
    fi
done

# Enable Enhanced Monitoring on new database
echo
echo "Enabling Enhanced Monitoring on $newdb"
aws rds modify-db-instance --db-instance-identifier $newdb --monitoring-role-arn arn:aws:iam::208766631402:role/leapdbreplica-emaccess --monitoring-interval 5 | grep -i "DBInstanceStatus"
echo
echo "Checking if Enhanced Monitoring is enabled on $newdb..."
echo "This process can take a while. Please wait."
echo
sleep 5
while :
do
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus")
    dbavailable=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus" | grep -i "available")
    if [[ "$dbstatus" == $dbavailable ]]; then
        echo "----------------------------------------------------------"
        echo "Enhaced Monitoring has been enabled on $newdb"
        echo "----------------------------------------------------------"
        break
    fi
done

# Enable Performance Insights on new database"
echo
echo "Enabling Performance Insights on $newdb"
aws rds modify-db-instance --db-instance-identifier $newdb --enable-performance-insights | grep -i "PerformanceInsightsEnabled"
echo
echo "Checking if Performance Insights is enabled on $newdb..."
echo "This process can take a while. Please wait."
echo
while :
do
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus")
    dbavailable=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus" | grep -i "available")
    if [[ "$dbstatus" == $dbavailable ]]; then
        echo "------------------------------------------------------------"
        echo "Performance Insights has been enabled on $newdb"
        echo "------------------------------------------------------------"
        break
    fi
done

# Check if new database is available
echo
echo "Checking if $newdb is available and online..."
echo "This process can take a while. Please wait."
echo
while :
do
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus")
    dbavailable=$(aws rds describe-db-instances --db-instance-identifier $newdb | grep -i "DBInstanceStatus" | grep -i "available")
    if [[ "$dbstatus" == $dbavailable ]]; then
        echo "--------------------------------"
        echo "$newdb is available"
        echo "--------------------------------"
        break
    fi
done

# Report how long the script took to execute
duration="Duration of script: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo
echo $duration
