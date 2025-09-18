To create an IAM user in Terraform that can access your S3 bucket from CloudFront, you'll need to define an IAM user, create an IAM policy allowing access to the specific S3 bucket, and then attach that policy to the IAM user. Additionally, a CloudFront origin access identity might be needed to provide further security and control. [1, 2]  
Here's a breakdown of the process: 
1. Create an IAM User: 
resource "aws_iam_user" "s3_access_user" {
  name = "s3-access-user"
}

2. Define an IAM Policy for S3 Access: 
resource "aws_iam_policy" "s3_bucket_policy" {
  name = "s3-bucket-policy"
  description = "Policy to allow S3 access for CloudFront"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:GetObject",
          "s3:ListBucket" # (Optional) Allow listing the bucket contents
        ],
        "Resource" = ["arn:aws:s3:::${var.s3_bucket_name}", "arn:aws:s3:::${var.s3_bucket_name}/*"] # Replace with your S3 bucket name
      },
    ]
  })
}

3. Attach the Policy to the IAM User: 
resource "aws_iam_user_policy_attachment" "attach_s3_policy" {
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
  user = aws_iam_user.s3_access_user.name
}

4. (Optional) Create a CloudFront Origin Access Identity: 
If you want to restrict access to your S3 bucket to only CloudFront, you can create an Origin Access Identity and use it in your CloudFront distribution configuration. 
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin Access Identity for S3 bucket"
}

5. (Optional) Use the Origin Access Identity in your CloudFront Distribution: 
In your CloudFront distribution, use the s3_origin_config to specify the origin access identity. 
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  # ... other CloudFront configuration
  origin {
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
}

Important Considerations: 

• Security: Always use the principle of least privilege. Grant the IAM user only the necessary permissions. 
• IAM Roles: Consider using IAM roles instead of users, especially if you're managing access for AWS services or applications. 
• Bucket Policies: You might need to configure a bucket policy on your S3 bucket to allow access from the IAM user or CloudFront. 
• Origin Access Control (OAC): Consider using OAC for s3-cloudfront for more fine-grained control. 

This comprehensive approach ensures that your S3 bucket is securely configured and that the IAM user has the necessary permissions to interact with it through CloudFront. 

Generative AI is experimental.

[1] https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity[2] https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control[-] https://groups.google.com/g/terraform-tool/c/2BXYJSlNnig
Not all images can be exported from Search.
