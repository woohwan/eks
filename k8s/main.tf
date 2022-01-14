provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "ms-up-running" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "ms-up-running" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.ms-up-running.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.ms-up-running.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.ms-up-running.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.ms-up-running.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.ms-up-running.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.ms-up-running.token
  }
}

resource "local_file" "kubeconfig" {
  sensitive_content = templatefile("${path.module}/kubeconfig.tpl", {
      cluster_name = var.cluster_name,
      clusterca = data.aws_eks_cluster.ms-up-running.certificate_authority[0].data,
      endpoint = data.aws_eks_cluster.ms-up-running.endpoint,
  })
  filename = "./kubeconfig-${var.cluster_name}"
}

resource "kubernetes_namespace" "example" {
  metadata {
      name = "argo"
  }
}

resource "helm_release" "argocd" {
  name = "msur"
  chart = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace = "argo"
}