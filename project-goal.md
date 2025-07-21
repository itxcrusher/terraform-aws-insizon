## Update



# App with dash
1. app.yaml - I want to be able to create app names with (-). Ex. insizon-app
However, I think that the split method will remove the dash. I still want the format
"${appName}-{environment}"


## Add limit property
1. I want to be able to limit user to specific app. 
if limit property is found in (user-roles.yaml) file. Those are the only 
resources that that user has access too. (aws, cloudfront, secret manager, etc)


## Trust keygroup
1. Figure out how to have multiple public keys in a single keygroup as each aws account
can only have so many seperate key groups. However, each aws account can have upto 100 public keys for a single keygroup
2. KeyGroupName: dev-key-group property doesn't work


## Create AWS Lamda function module that is trigger by Event Bridge and Http
1. You might have to create new yaml file for this
Name: "test-app"
Event: [Timer, Http]
Timer:
  Cron: "0 0 0 0 10"
  Http: "POST http://www.insizon.com"


## Create aws budget different services
1. Crate local block with diff comparison operators
2. threshold_type
3. notification_type 
4. time_unit
5. limit_unit
6. budget type
7. Create yaml files name budget. Ex
  name: test-budget
  Budget: 
      limit_amount: 10
      comparison_operator: GREATER_THAN
      threshold: 80
      EmailRecipients: 
        - test@gmail.com
        - test1@gmail.com


## Create Elastic Beanstalk module
1. Create local block for Nodejs, Python, Dotnet
2. Should read from yaml file app.yaml and have these properties.
Note: if ServiceName is doesn't exist it should use the app name.
If the ElasticBeanStock doesn't exist or CreateService is false
don't create resource
 ElasticBeanStock: 
      ServiceName: "test-app2"
      CreateService: true
      other properties


## Create module for nodejs docker container
1. Amazon Elastic Container Registry (ECR): Create an ECR repository to store your Docker image.
2. Should read from yaml file app.yaml and have these properties.
Note: if ServiceName is doesn't exist it should use the app name.
If the ElasticContainerRegistry doesn't exist or CreateService is false
don't create resource
 ElasticContainerRegistry: 
      ServiceName: "test-app2"
      CreateService: true
      other properties

## Aws S3 
0. Should create a folder public folder that will hold static files
1. Upload folder files with folder based on yaml file. (Basically if FolderName property is not empty search for this )
2. Create module that creates bucket named insizon-static-bucket
3. This module will read from (static-files.yaml) and will have 
properties like 
FolderName
FilesExcluded
  - file2.txt
  - file2.txt
  - photo.img
that will create folder subfolder base on yaml property FolderName and will add all files. Unless the FileExcluded property is found and will avoid adding those files to subfolder bucket



## Project Update


# Project looks good so far. Just need a few fixes


## static-files.yaml
1. It should create one aws s3 bucket named "static_bucket" with multiple
subfolder named from appName in yaml file
Example
static_files:
  static_folder_name: static-bucket
  apps:
    - app_name: insizon-app-dev
      files_excluded:
        - photo.png

for example in s3, static_bucket -> insizon_app-dev-> all insizon static files here will be uploaded besides ones that are excluded


## sns.yaml
1. I would like the yaml objects to look like this structure
2. Also, the sns needs to have a field to set region as the sns are in different region than the region in provider.tf
sns:
  - sns_collection_name: insizon
    region: "us-east-1"
    bounces:
      name: "email-insizon-bounces"
      endpoint: "https://service-api-worker-backend-app-5cc5274304b1.herokuapp.com/api/insizon/email/email-bounces"
      protocols: ["https"]
    complaints:
      name: "email-insizon-complaints"
      endpoint: "https://service-api-worker-backend-app-5cc5274304b1.herokuapp.com/api/insizon/email/email-complaints"
      protocols: ["https"]
    deliveries:
      name: "email-insizon-deliveries"
      endpoint: "https://service-api-worker-backend-app-5cc5274304b1.herokuapp.com/api/insizon/email/email-deliveries"
      protocols: ["https"]




