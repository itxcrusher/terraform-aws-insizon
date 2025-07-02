########################################################################
# Per-environment EC2 role & instance profile (Beanstalk only)
########################################################################

resource "aws_iam_role" "beanstalk_ec2" {
  name        = "${var.cfg.env}-${var.cfg.service_name}-beanstalk-ec2-role"
  description = "EC2 role for Beanstalk (${var.cfg.service_name} - ${var.cfg.env})"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_managed" {
  role       = aws_iam_role.beanstalk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "beanstalk_profile" {
  name = "${var.cfg.env}-${var.cfg.service_name}-beanstalk-profile"
  role = aws_iam_role.beanstalk_ec2.name
}

output "beanstalk_instance_profile_name" {
  value = aws_iam_instance_profile.beanstalk_profile.name
}
