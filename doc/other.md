# Helpful




## Topics
1. Modules
    * Root module - The core director where you run the terraform commands
    * Root module Module is a collection of terraform files in a folder
2. Data Source
    * Data sources - Allow you to fetch data or computed for use elsewhere in terraform configuration.
    * Kinda like a api GET
    * Every resource has a data source
3. Variables 
    * Local - File scoped
    * Global - Can be called in another file
4. Output block
    * Allows you to print a variable
    * Allows you to print a data source fetch
    * Use command (To print)- terraform output 
    * Start with data. or var. or local.



## Terraform Login (Provider)
1. Hardcoded
    * access_key = "<access_key>"
    * secret_key = "<secret_key>"
2. Environment Vars - Recommended
    * export AWS_ACCESS_KEY_ID = "<access_key>"
    * export AWS_SECRET_ACCESS_KEY = "<secret_key>"
    * export AWS_REGION = "<region>"
3. Aws config cmd
    * aws configure
4. Aws config profile
    * shared_config_files = "[/users/tf_user/.aws/conf]"
    * shared_credential_files = "[/users/tf_user/.aws/creds]"
    * profiles = "customprofile"


# How to get access key
1. AWS Console -> IAM - Create New User -> Security Cred -> Create Access Key -> Local Code

## Helpful Links
1. https://www.youtube.com/watch?v=7jnuTdhxjhw
2. How to mamange secret terraform - https://www.youtube.com/watch?v=3N0tGKwvBdA
3. 6 Different ways to use TF AWS Provider AUth - https://www.youtube.com/watch?v=JZRMA1NyNlE
4. https://kavyajayan.medium.com/terraform-use-variables-and-output-root-level-to-module-level-3cf8dffffcdf
5. Terraform State
https://www.youtube.com/watch?v=LzWBPIgbrXM
6. Github Action Terraform
https://www.youtube.com/watch?v=GowFk_5Rx_I
7. Terraform State Lock
https://www.youtube.com/watch?v=MxdvSgoWK7E