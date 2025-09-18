#!/bin/bash
# Delete Single Cloudfront Key
# exit 0 -> Failed, exit 1 -> Success
# Private key upload to your backend server Cloudfront will use this key to sign all the urls before servering images to users
# Public key upload to cloudfront key section. Cloudfront will use this key to verify that the image is not expired and authorized to view
# https://www.youtube.com/watch?v=EIYrhbBk7do
environment="dev"
appName="maxgeneyexcontractor"
folder="../private/cloudfront_keys"


# create_Keys arg1 arg2
delete_Keys() {
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
    echo "About to delete $1 public and private key"
    echo "You have 10 seconds to stop this script"
    sleep 1
    rm "$fileNamePrivate"
    rm "$fileNamePublic"
  else
    echo "The $1 private and public key doesn't exist"
    sleep 1
  fi
}


delete_Keys "$appName" "$environment"