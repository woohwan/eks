data "aws_subnet_ids" "ms-vpc" {
  vpc_id = data.aws_vpc.ms-vpc.id
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.ms-vpc.id
  tags = {
    "Name" = "*private*"
  }
}


resource "aws_eks_cluster" "ms-up-running" {
  name = var.cluster_name
  #   version  = var.kubernetes_version
  role_arn = aws_iam_role.ms-cluster.arn

  vpc_config {
    subnet_ids = data.aws_subnet_ids.ms-vpc.ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.ms-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.ms-cluster-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "ms-node-group" {
  cluster_name    = aws_eks_cluster.ms-up-running.name
  node_group_name = "microservices"
  node_role_arn   = aws_iam_role.ms-node.arn
  subnet_ids      = data.aws_subnet_ids.private.ids
  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.ms-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ms-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ms-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
