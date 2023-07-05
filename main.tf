provider "aws" {
  region = "eu-west-2"
}

data "aws_eks_cluster" "cluster" {
  name = "test-eks-NjifgyBd"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "test-eks-NjifgyBd"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster_auth.cluster.id]
      command     = "aws"
    }
  }
}

locals {
  default_helm_values = [file("${path.module}/values.yaml")]

  name      = "argo-cd"
  namespace = "argocd-new"
  # https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/Chart.yaml
  default_helm_config = {
    name             = "repo-server-169643"
    chart            = local.name
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "5.13.8"
    namespace        = local.namespace
    create_namespace = true
    values           = local.default_helm_values
    description      = "The ArgoCD Helm Chart deployment configuration"
    wait             = false
  }

  helm_config = local.default_helm_config


}


variable "dockerconfigjson" {
  type    = string
  default = "{\"auths\":{\"docker-enterprise.prod.local\":{\"auth\":\"dXNlcjpzdXBlcnNlY3JldHBhc3N3b3JkCg==\"}}}"
}

locals {
  dockerconfigjson = jsondecode(var.dockerconfigjson)
  authValue        = local.dockerconfigjson.auths["docker-enterprise.prod.local"].auth
  transformedAuth  = replace(base64decode(local.authValue), "user:", "")
}



resource "helm_release" "test" {
  name                       = local.helm_config["name"]
  repository                 = try(local.helm_config["repository"], null)
  chart                      = local.helm_config["chart"]
  version                    = try(local.helm_config["version"], null)
  timeout                    = try(local.helm_config["timeout"], 1200)
  values                     = try(local.helm_config["values"], null)
  create_namespace           = try(local.helm_config["create_namespace"], false)
  namespace                  = local.helm_config["namespace"]
  lint                       = try(local.helm_config["lint"], false)
  description                = try(local.helm_config["description"], "")
  repository_key_file        = try(local.helm_config["repository_key_file"], "")
  repository_cert_file       = try(local.helm_config["repository_cert_file"], "")
  repository_username        = try(local.helm_config["repository_username"], "")
  repository_password        = local.transformedAuth #try(local.helm_config["repository_password"], "")
  verify                     = try(local.helm_config["verify"], false)
  keyring                    = try(local.helm_config["keyring"], "")
  disable_webhooks           = try(local.helm_config["disable_webhooks"], false)
  reuse_values               = try(local.helm_config["reuse_values"], false)
  reset_values               = try(local.helm_config["reset_values"], false)
  force_update               = try(local.helm_config["force_update"], false)
  recreate_pods              = try(local.helm_config["recreate_pods"], false)
  cleanup_on_fail            = try(local.helm_config["cleanup_on_fail"], false)
  max_history                = try(local.helm_config["max_history"], 0)
  atomic                     = try(local.helm_config["atomic"], false)
  skip_crds                  = try(local.helm_config["skip_crds"], false)
  render_subchart_notes      = try(local.helm_config["render_subchart_notes"], true)
  disable_openapi_validation = try(local.helm_config["disable_openapi_validation"], false)
  wait                       = try(local.helm_config["wait"], true)
  wait_for_jobs              = try(local.helm_config["wait_for_jobs"], false)
  dependency_update          = try(local.helm_config["dependency_update"], false)
  replace                    = try(local.helm_config["replace"], false)
}

/* data "external" "decode_auth" {
  program = ["bash", "-c", "date"]
  query = {
    file = var.dockerconfigjson
  }
} */


/* resource "null_resource" "secret" {
  provisioner "local-exec" {
    command = "kubectl get svc prometheus-server -n monitoring | awk -F' ' '{print $3}' | tail -1 | tr -d '\n' >> ${path.module}/prometheus_private_ips.txt"
  }
}

data "local_file" "secret" {
  content  = var.dockerconfigjson
    /* filename = "${path.module}/prometheus_private_ips.txt" */

/* resource "helm_release" "example" {
  name      = "example"
  chart     = "example-chart"
  namespace = "default"

  repository_password = "${data.local_file.secret.content}"
}
} */