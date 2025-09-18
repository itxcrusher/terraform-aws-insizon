#/bin/bash
# Shell script to pull/clone all lambda functions from repo and then zip folder
# before being uploaded to beanstlack
# TODO: Look into serverless deploy cli - https://www.youtube.com/watch?v=MHv_4v-hfXo
destinationFolderArray=("dev")
appNameArray=("insizon" "maxgeneye")
# function_name=("process-insizon" "process-maxgeneye")


# --- Script Logic ---

# $1 - LambdaName
# $2 - DestinationName -
# $3 - 
Clone_Latest_Lambda() {
  if [ -z "$1" ] || [ -z "$2" ];
  then
    echo "Arg is empty"
    exit 1
  fi

  # --- Configuration ---
  # Replace with your classic GitHub PAT
  GITHUB_TOKEN="YOUR_CLASSIC_GITHUB_TOKEN" 
  # Replace with your repository URL
  REPO_URL="https://github.com/insizon/${1}Lambda.git" 
  # Replace with the desired destination folder
  DESTINATION_FOLDER="../private/lambda/${1}-${2}"
  # Name of the output zip file
  ZipName="process-${1}.zip" 


  # Create the destination folder if it doesn't exist
  mkdir -p "$DESTINATION_FOLDER"

  # Clone the repository into the destination folder using the PAT
  git clone "https://${GITHUB_TOKEN}@$(echo "$REPO_URL" | sed -e 's/^https:\/\///')" "$DESTINATION_FOLDER"

  if [ $? -eq 0 ]; 
  then
      echo "Repository cloned successfully into: $DESTINATION_FOLDER"
      Zip_Clone_Lambda $DESTINATION_FOLDER $ZipName
  else
      echo "Error: Failed to clone the repository."
      exit 1
  fi
}


Zip_Clone_Lambda() {
  if [ -z "$1" ] || [ -z "$2" ];
  then
    echo "Arg is empty"
    exit 1
  fi

  TargetDir=($1)
  ZipName=($2)

  # 2. Zip the cloned folder
  echo "Zipping the folder: $TargetDir into $ZipName..."
  zip -r "$ZipName" "$TargetDir"

  # Check if zipping was successful
  if [ $? -ne 0 ]; 
  then
      echo "Error: Zipping failed."
      exit 1
  fi

  echo "Folder zipped successfully: $ZipName"
}



Start() {
  for appEnv in "${destinationFolderArray[@]}"; 
  do
    echo "Envioronments - $item"
    for appName in "${appNameArray[@]}"; 
    do
      Clone_Latest_Lambda $appName $appEnv
    done
  done
}