# Backend Setup





# Create s3 Bucket




# Create DynamoDB
- Note that you must recreate the dynamoDb lock file table when you delete tfstate file
- https://www.youtube.com/watch?v=MxdvSgoWK7E&t=829s
Table Name - dynamodb-aws-state-tfstate-locking
Partition Key - LockID - String
Settings
-> Default Setting