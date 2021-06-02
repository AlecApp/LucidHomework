data "aws_iam_policy" "allow_rds" {
  arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "worker_profile"
  role = aws_iam_role.worker_role.name
}

resource "aws_iam_role" "worker_role" {
  name = "worker_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "allow_rds" {
  role       = aws_iam_role.worker_role.name
  policy_arn = data.aws_iam_policy.allow_rds.arn
}
