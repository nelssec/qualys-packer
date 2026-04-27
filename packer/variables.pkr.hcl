variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to build in"
}

variable "source_ami_id" {
  type        = string
  default     = ""
  description = "Explicit source AMI ID. Takes precedence over filter if set."
}

variable "source_ami_filter_name" {
  type        = string
  default     = "al2023-ami-*-x86_64"
  description = "AMI name filter pattern for source AMI lookup"
}

variable "source_ami_owners" {
  type        = list(string)
  default     = ["amazon"]
  description = "Account IDs that own the source AMI (for filter)"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for the build"
}

variable "ssh_username" {
  type        = string
  default     = "ec2-user"
  description = "SSH username for connecting to the build instance"
}

variable "ami_name_prefix" {
  type        = string
  default     = "golden-ami"
  description = "Prefix for the output AMI name"
}

variable "ami_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to the output AMI"
}

variable "custom_scripts" {
  type        = list(string)
  default     = []
  description = "Paths to user provisioner scripts to run before QScanner scan"
}

variable "temporary_security_group_source_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed SSH access to the build instance. Set to your IP/CIDR to avoid 0.0.0.0/0."
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "VPC subnet ID for the build instance (optional)"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "VPC ID for the build instance (optional)"
}

variable "associate_public_ip" {
  type        = bool
  default     = true
  description = "Whether to assign a public IP to the build instance"
}

variable "use_session_manager" {
  type        = bool
  default     = false
  description = "Use SSM Session Manager instead of SSH. Requires SSM agent on AMI and IAM instance profile with SSM permissions."
}

variable "iam_instance_profile" {
  type        = string
  default     = ""
  description = "IAM instance profile to attach to the build instance"
}

variable "qualys_access_token" {
  type        = string
  default     = env("QUALYS_ACCESS_TOKEN")
  description = "Qualys access token for backend communication"
  sensitive   = true

  validation {
    condition     = var.qualys_access_token != ""
    error_message = "The qualys_access_token must be set via -var or QUALYS_ACCESS_TOKEN env var."
  }
}

variable "qualys_pod" {
  type        = string
  default     = "US1"
  description = "Qualys platform pod (US1, US2, US3, EU1, CA1, etc.)"
}

variable "qualys_scan_types" {
  type        = string
  default     = "os,sca,secret,fileinsight"
  description = "Comma-separated QScanner scan types"
}

variable "qualys_mode" {
  type        = string
  default     = "get-report"
  description = "QScanner mode: get-report (informational) or evaluate-policy (build gating)"

  validation {
    condition     = contains(["get-report", "evaluate-policy", "scan-only", "inventory-only"], var.qualys_mode)
    error_message = "The qualys_mode must be one of: get-report, evaluate-policy, scan-only, or inventory-only."
  }
}

variable "qualys_policy_tags" {
  type        = string
  default     = ""
  description = "Comma-separated policy tags for evaluate-policy mode"
}

variable "qualys_scan_timeout" {
  type        = string
  default     = "5m"
  description = "QScanner scan timeout"
}

variable "qualys_report_format" {
  type        = string
  default     = "table,sarif"
  description = "Comma-separated report output formats"
}

variable "qualys_exclude_dirs" {
  type        = string
  default     = "/proc,/sys,/dev,/run,/tmp"
  description = "Comma-separated directories to exclude from scan"
}

variable "fail_on_audit" {
  type        = bool
  default     = false
  description = "If true, AUDIT result (exit 43) also fails the build in evaluate-policy mode"
}

variable "qscanner_version" {
  type        = string
  default     = "latest"
  description = "QScanner version to download (e.g. 'latest', 'v4.8.0')"
}
