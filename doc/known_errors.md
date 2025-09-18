# Known Errors





### Access Denied
1. How to add IAM Policy to user
https://www.youtube.com/watch?v=F0a1UBne2QU
2. operation error S3: CreateBucket, https response error StatusCode: 409, RequestID:
Issue is because the bucket name already exists in some other customer's account
https://github.com/aws/aws-sdk-go-v2/issues/1740
3. Tags characters not allowed
Disallowed=[, &]
Allowed=[_, ., :, /, =, +, @, -, and "]
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-resource-tags.html#w2ab1c25c10d254c13c17




## Data Source
1. When running terraform plan - No Changes message will appear as data source blocks is just getting info