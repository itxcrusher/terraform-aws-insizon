#!/bin/bash

# Specify the AWS region
REGION="us-east-2" # Replace with your desired region

# Get a list of all Elastic Beanstalk applications in the specified region
applications=$(aws elasticbeanstalk describe-applications --region "$REGION" --query "Applications[*].ApplicationName" --output text)

# Check if any applications were found
if [ -z "$applications" ]; 
then
  echo "No Elastic Beanstalk applications found in region $REGION."
else
  echo "Elastic Beanstalk Applications in region $REGION:"
  # Iterate through the applications
  for app in $applications; do
    echo "  Application: $app"

    # Get a list of environments for the current application
    environments=$(aws elasticbeanstalk describe-environments --application-name "$app" --region "$REGION" --query "Environments[*].EnvironmentName" --output text)

    # Check if any environments were found for the application
    if [ -z "$environments" ]; 
    then
      echo "    No environments found for this application."
    else
      echo "    Environments:"
      # Iterate through the environments and list their names
      for env in $environments; do
        echo "      - $env"
      done
    fi
  done
fi
