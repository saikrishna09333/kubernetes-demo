variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_subscription_id" {}
variable "azure_tenant_id" {}

variable resource_group_name {}

variable location {}
variable "vnet_name" {}
variable "address_space" {}

variable "subnet_prefixes" {}

variable "subnet_names" {}

variable "agent_count" {}

variable "ssh_public_key" {}

variable "dns_prefix" {}

variable cluster_name {}



variable log_analytics_workspace_name {}

variable log_analytics_workspace_location {}

variable log_analytics_workspace_sku {}
locals {
  http_container_port   = "44135"
  tiller_container_port = "44134"

  labels = {
    app  = "helm"
    name = var.tiller_name
  }
}

variable "tiller_name" {}

variable "tiller_namespace" {}

variable "tiller_version" {}

variable "tiller_service_type" {}

variable "tiller_history_max" {}

variable "tiller_image_pull_policy" {}
