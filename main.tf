
module "main-vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "vpc-${var.env}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c", "${var.aws_region}d", "${var.aws_region}e", "${var.aws_region}f"]
  private_subnets = ["10.0.0.0/20", "10.0.32.0/20", "10.0.64.0/20", "10.0.96.0/20", "10.0.128.0/20", "10.0.160.0/20"]
  public_subnets  = ["10.0.16.0/21", "10.0.48.0/21", "10.0.80.0/21", "10.0.112.0/21", "10.0.144.0/21", "10.0.176.0/21"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_iam_role.arn
  log_destination = aws_cloudwatch_log_group.cloudwatch_logs.arn
  traffic_type    = "ALL"
  vpc_id          = module.main-vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "cloudwatch_logs" {
  name = "vpc-xtages-flow-logs"
  retention_in_days = 14
}

resource "aws_iam_role" "flow_log_iam_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.flow_log_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
