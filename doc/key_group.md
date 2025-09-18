A CloudFront key group can hold a list of public keys, and an AWS account can have a maximum of 10 key groups. Each CloudFront distribution can be associated with a maximum of 4 key groups. When creating key groups, you can have up to 10 public keys in each key group. [1, 2, 3]  
Here's a more detailed breakdown: [2]  

• Key Groups: An AWS account can have a maximum of 10 key groups. [2]  
• Key Groups per Distribution: Each CloudFront distribution can be associated with a maximum of 4 key groups. [2]  
• Public Keys per Key Group: You can have up to 10 public keys within each key group. [3]  
• Private Keys: You'll also need to have the corresponding private keys associated with each public key, which are stored securely in your AWS account. [4]  
• Root User: Only the root AWS user can create and manage key pairs. [1]  
• Key Rotation: For key rotation, the root user can have up to two key pairs for key rotation purposes. [1]  
• Trusted Signers: You can specify different accounts as trusted signers and limit them to specific distributions. [1]  

Generative AI is experimental.

[1] https://stackoverflow.com/questions/61314278/how-can-i-create-development-and-production-cloudfront-key-pairs[2] https://docs.aws.amazon.com/general/latest/gr/cf_region.html[3] https://www.reddit.com/r/aws/comments/12yxspb/rotating_cloudfront_public_keys_with_iac_and/[4] https://github.com/aws-samples/amazon-cloudfront-signed-urls-using-lambda-secretsmanager/blob/main/3-Create_CloudFront_Key_Groups/README.md
