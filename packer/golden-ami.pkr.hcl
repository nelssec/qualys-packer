packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "golden_ami" {
  region        = var.region
  instance_type = var.instance_type
  ssh_username  = var.ssh_username
  source_ami    = var.source_ami_id != "" ? var.source_ami_id : null

  dynamic "source_ami_filter" {
    for_each = var.source_ami_id == "" ? [1] : []
    content {
      filters = {
        name                = var.source_ami_filter_name
        root-device-type    = "ebs"
        virtualization-type = "hvm"
      }
      most_recent = true
      owners      = var.source_ami_owners
    }
  }

  ami_name = "${var.ami_name_prefix}-{{timestamp}}"

  tags = merge(
    {
      Name      = "${var.ami_name_prefix}-{{timestamp}}"
      BuildTime = "{{timestamp}}"
      BaseAMI   = "{{ .SourceAMI }}"
      Scanner   = "QScanner"
    },
    var.ami_tags
  )

  ssh_interface                         = var.use_session_manager ? "session_manager" : null
  subnet_id                             = var.subnet_id != "" ? var.subnet_id : null
  vpc_id                                = var.vpc_id != "" ? var.vpc_id : null
  associate_public_ip_address           = var.use_session_manager ? false : var.associate_public_ip
  iam_instance_profile                  = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  temporary_security_group_source_cidrs = var.use_session_manager ? [] : (length(var.temporary_security_group_source_cidrs) > 0 ? var.temporary_security_group_source_cidrs : ["0.0.0.0/0"])
}

build {
  sources = ["source.amazon-ebs.golden_ami"]

  dynamic "provisioner" {
    labels   = ["shell"]
    for_each = var.custom_scripts
    content {
      script = provisioner.value
    }
  }

  provisioner "shell" {
    script = "${path.root}/../scripts/install-qscanner.sh"
    environment_vars = [
      "QSCANNER_VERSION=${var.qscanner_version}",
    ]
  }

  provisioner "shell" {
    script = "${path.root}/../scripts/run-qscanner-scan.sh"
    environment_vars = [
      "QUALYS_ACCESS_TOKEN=${var.qualys_access_token}",
      "QUALYS_POD=${var.qualys_pod}",
      "QUALYS_MODE=${var.qualys_mode}",
      "QUALYS_SCAN_TYPES=${var.qualys_scan_types}",
      "QUALYS_REPORT_FORMAT=${var.qualys_report_format}",
      "QUALYS_EXCLUDE_DIRS=${var.qualys_exclude_dirs}",
      "QUALYS_SCAN_TIMEOUT=${var.qualys_scan_timeout}",
      "QUALYS_POLICY_TAGS=${var.qualys_policy_tags}",
      "FAIL_ON_AUDIT=${var.fail_on_audit}",
    ]
  }

  provisioner "file" {
    source      = "/tmp/qscanner-output/"
    destination = "${path.root}/../output/"
    direction   = "download"
  }

  provisioner "shell" {
    script = "${path.root}/../scripts/cleanup-qscanner.sh"
  }
}
