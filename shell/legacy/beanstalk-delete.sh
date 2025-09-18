#!/bin/bash



# Define your Elastic Beanstalk application name and the corresponding S3 bucket name
BEANSTALK_APP_NAME="YOUR_BEANSTALK_APPLICATION_NAME"  # Replace with your actual application name
S3_BUCKET_NAME="elasticbeanstalk-us-east-2-252925426330"                 # Replace with your actual S3 bucket name

# Check if the Elastic Beanstalk application exists
# aws elasticbeanstalk describe-applications --application-names "${BEANSTALK_APP_NAME}" > /dev/null 2>&1

# # Check the exit code of the previous command
# if [ $? -eq 0 ]; 
# then
#     echo "Elastic Beanstalk application '${BEANSTALK_APP_NAME}' exists. No action needed for the S3 bucket."
# else
    echo "Elastic Beanstalk application '${BEANSTALK_APP_NAME}' does NOT exist."
    echo "Attempting to delete S3 bucket '${S3_BUCKET_NAME}'."
    sleep 5

    # Delete the S3 bucket recursively (empty it first, then delete)
    # BE EXTREMELY CAREFUL with this command, as it will permanently delete the bucket and its contents.
    aws s3 rm s3://${S3_BUCKET_NAME} --recursive
    if [ $? -eq 0 ]; then
        echo "Successfully emptied S3 bucket '${S3_BUCKET_NAME}'."

        aws s3 rb s3://${S3_BUCKET_NAME}
        if [ $? -eq 0 ]; then
            echo "Successfully deleted S3 bucket '${S3_BUCKET_NAME}'."
        else
            echo "Error deleting S3 bucket '${S3_BUCKET_NAME}'."
        fi
    else
        echo "Error emptying S3 bucket '${S3_BUCKET_NAME}'. It might not exist, or you may lack permissions."
    fi
# fi
