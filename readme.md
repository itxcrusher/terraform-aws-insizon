# TerraformAWS




## TODO
- Secondary
2. Create Amazon simple Email Service
- Other





# Each subfolder must be imported into root module using the module syntax


## How to run
- Navigate into the root terraform module and run these commands
1. Will setup the terraform providers. Whenever you add a new provider or change terraform backend you have to rerun this command
terraform init or 
terraform init -migrate-state (If you made changes and select yes to keep old state)
2. See what resources will be created after you run terrafrom apply
terraform plan
or 
terraform plan -var-file="dev.tfvars"
3. The resources that will be created and saved in state.tf file
terraform apply
4. Print all outputs
terraforn output
5. Delete all the resources that is management in tf state. Warning!!
terraform destory
6. Format terraform files for better readability
terraform fmt or terraform fmt -recursive
7. Cmd to validate if there's any invalid values
terraform validate


## S3 Cloudfron 
1. https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html
2. https://repost.aws/questions/QU87GsmIg7Ry222yLx5Oolng/access-denied-accessing-cloudfront-distribution-signed-url-from-node-js
3. Aws new and old
https://www.youtube.com/watch?v=Ej0lDpBv7Cw