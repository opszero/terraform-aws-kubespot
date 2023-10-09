# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
module "iam_assumable_role_efs_csi" {
  count            = var.efs_enabled ? 1 : 0
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "5.3.0"
  create_role      = true
  role_name        = "${var.environment_name}-AmazonEFSCSIDriverPolicy"
  provider_url     = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"]
  # namespace and service account name
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:efs-csi-controller-sa",
    "system:serviceaccount:kube-system:efs-csi-node-sa",
    "system:serviceaccount:kube-system:efs-csi-*",
  ]
  oidc_fully_qualified_audiences = [
    "sts.amazonaws.com"
  ]
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_efs_file_system" "file_system" {
  count = var.efs_enabled ? 1 : 0

  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name        = "${var.environment_name}-eks-efs"
    Environment = var.environment_name
  }
}

resource "aws_efs_mount_target" "mount_target" {
  count           = var.efs_enabled ? length(var.cidr_block_private_subnet) : 0

  file_system_id  = aws_efs_file_system.file_system.id
  subnet_id       = var.cidr_block_private_subnet[count.index]
  security_groups = [aws_security_group.mount_target_security_group.id]
}


resource "aws_security_group" "mount_target_security_group" {
  count = var.efs_enabled ? 1 : 0
  
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name        = "${var.environment_name}-eks-efs-sg"
    Environment = var.environment_name
  }
}
