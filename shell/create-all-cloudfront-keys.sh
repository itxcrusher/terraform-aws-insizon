#!/bin/bash
# Generate Cloudfront Key
# exit 0 -> Failed, exit 1 -> Success
# Private key upload to your backend server Cloudfront will use this key to sign all the urls before servering images to users
# Public key upload to cloudfront key section. Cloudfront will use this key to verify that the image is not expired and authorized to view
# https://www.youtube.com/watch?v=EIYrhbBk7do
# https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
environmentArray=("prod" "qa" "dev")
appNameArray=("insizon")

# How to install openssl
# brew install openssl




# create_Keys arg1 arg2
create_Keys() {
  if [ -z "$1" ] || [ -z "$2" ];
  then
    echo "Arg is empty"
    exit 1
  fi

  fileNamePrivate="../private/cloudfront/rsa_keys/private/$1-$2-private-key.pem"
  fileNamePublic="../private/cloudfront/rsa_keys/public/$1-$2-public-key.pem"
  # How to generate cloudfron key
  if [ -e "$fileNamePrivate" ] || [ -e "$fileNamePublic" ]
  then
    echo "File already exist. Please delete it to continue"
  else
    echo "About to create $1 private key"
    sleep 1
    # Don't add the 2048 at the end creates weird bug with cloudfront
    openssl genrsa -out "$fileNamePrivate"

    echo "About to create $1 public key from private key"
    sleep 1
    openssl rsa -pubout -in "$fileNamePrivate" -out "$fileNamePublic"
  fi
}



generate_keys() {
  for appEnv in "${environmentArray[@]}"; 
  do
    echo "Envioronments - $item"
    for appName in "${appNameArray[@]}"; 
    do
      create_Keys $appName $appEnv
    done
  done
}



delete_key() {
  echo "Delete a specific key"
}


prompt_select() {
  title="Select example"
  prompt="Pick an option:"
  options=("Generate Keys" "Delete Key" "Help")

  echo "$title"
  PS3="$prompt "
  select opt in "${options[@]}" "Quit"; 
  do 
      case "$REPLY" in
      1) 
        echo "You picked $opt which is option 1"
        generate_keys
        break
        ;;
      2) 
        echo "You picked $opt which is option 2"
        echo "You have 10sec to cancel before all private and public keys are deleted"
        sleep 10
        fileNamePrivate="../private/cloudfront/rsa_keys/private/*"
        fileNamePublic="../private/cloudfront/rsa_keys/public/*"
        rm -rf $fileNamePrivate
        rm -rf $fileNamePublic
        break
        ;;
      3) 
        echo "You picked $opt which is option 3"
        break
        ;;
      4) 
        echo "Goodbye!"; 
        break
        ;;
      *) 
        echo "Invalid option. Try another one.";
        continue
        ;;
      esac
  done
}


prompt_select