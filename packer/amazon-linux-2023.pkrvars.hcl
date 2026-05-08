region                 = "us-east-1"
source_ami_filter_name = "al2023-ami-*-x86_64"
source_ami_owners      = ["amazon"]
instance_type          = "t3.medium"
ssh_username           = "ec2-user"
ami_name_prefix        = "golden-ami-al2023"

ami_tags = {
  OS      = "Amazon Linux 2023"
  Purpose = "Golden AMI"
}

qualys_pod        = "CA1"
qualys_mode       = "get-report"
qualys_scan_types = "os,sca,secret,fileinsight"
