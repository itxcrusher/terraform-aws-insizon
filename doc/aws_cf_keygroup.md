To add a public key to a CloudFront KeyGroup using the AWS CLI, you first need to create a public key resource and then add it to the key group. You'll need the public key in PEM format and the key group's ID. The aws cloudfront create-public-key command creates the public key, and aws cloudfront update-key-group adds it to the key group. [1, 1, 2, 2, 3, 4]  
Here's a breakdown of the process: 
1. Create the Public Key: 

• Use the aws cloudfront create-public-key command, providing a JSON file with the public key configuration. [1]  
• The JSON file should contain the public key in PEM format, a name, and an optional comment. [1, 2]  

aws cloudfront create-public-key --public-key-config file://<path_to_public_key_config_json>

Example pub-key-config.json: [1]  
{
  "CallerReference": "unique-caller-reference-string",
  "Name": "my-public-key-name",
  "EncodedKey": "MIIBIjANBgkqh...[rest of your public key]...RwIDAQAB",
  "Comment": "Optional comment about the key"
}

2. Get the Key Group ID: 

• You'll need the ID of the KeyGroup you want to update. You can find this ID by: 
	• Listing existing key groups using aws cloudfront list-key-groups. 
	• Or, if the key group is associated with a distribution, you can find its ID in the distribution's configuration. [5]  

3. Update the Key Group: 

• Use the aws cloudfront update-key-group command, providing the key group ID and the updated configuration. 
• The updated configuration includes the key group's name, comment (optional), and the list of public key IDs. [2, 2]  

aws cloudfront update-key-group --id <key_group_id> --if-match <etag> --key-group-config file://<path_to_updated_key_group_config_json>

Example updated-key-group-config.json: 
{
  "Name": "my-key-group-name",
  "Items": [
    "public_key_id_1",
    "public_key_id_2"
  ],
  "Comment": "Updated key group with a new public key"
}

Important Notes: 

• You need to replace placeholders like &lt;path_to_public_key_config_json&gt;, &lt;key_group_id&gt;, &lt;etag&gt;, public_key_id_1, etc., with your actual values. [1, 2]  
• The --if-match &lt;etag&gt; parameter is required when updating a resource and ensures you are updating the correct version. Get the ETag from the Get or List response of the resource you are updating. [2, 5]  
• You can get the ETag of the keygroup by using aws cloudfront get-key-group. [5, 6]  
• After updating the key group, you need to update your CloudFront distribution to use the new key group. [7]  
• When updating the key group, make sure to include all the public keys that should be in the key group, not just the new one. [2]  
• The public key ID is the identifier returned when you create the public key. [8, 8]  


[1] https://docs.aws.amazon.com/cli/latest/reference/cloudfront/create-public-key.html[2] https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateKeyGroup.html[3] https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html[4] https://stackoverflow.com/questions/66348050/public-key-creation-in-aws-cloudformation-giving-following-error-invalid-reques[5] https://docs.aws.amazon.com/goto/aws-cli/cloudfront-2020-05-31/GetKeyGroupConfig[6] https://docs.aws.amazon.com/cli/latest/reference/cloudfront/get-key-group-config.html[7] https://rajrajhans.com/2023/01/private-cloudfront-configuration/[8] https://docs.aws.amazon.com/cli/latest/reference/cloudfront/get-public-key.html
