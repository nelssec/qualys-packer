region                 = "us-east-1"
source_ami_filter_name = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
source_ami_owners      = ["099720109477"]
instance_type          = "t3.medium"
ssh_username           = "ubuntu"
ami_name_prefix        = "golden-ami-ubuntu-2404"

ami_tags = {
  OS      = "Ubuntu 24.04"
  Purpose = "Golden AMI"
}

qualys_pod         = "US1"
qualys_mode        = "evaluate-policy"
qualys_scan_types  = "os,sca,secret,fileinsight"
qualys_policy_tags = "production"
fail_on_audit      = true
