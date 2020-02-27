resource "azurerm_resource_group" "k8s" {
  name     = var.resource_group_name
  location = var.location
}
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
}
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  address_space       = [var.address_space]
  resource_group_name = azurerm_resource_group.k8s.name
  //  dns_servers         = var.dns_servers
  //  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_names
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.k8s.name
  //  count                = length(var.subnet_names)
  address_prefix = var.subnet_prefixes
}
resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "test" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.log_analytics_workspace_location
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "test" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.test.location
  resource_group_name   = azurerm_resource_group.k8s.name
  workspace_resource_id = azurerm_log_analytics_workspace.test.id
  workspace_name        = azurerm_log_analytics_workspace.test.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
resource "azurerm_container_registry" "acr" {
  name                = "snpregistry001"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = var.dns_prefix

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = tls_private_key.keypair.public_key_openssh
    }
  }
  service_principal {
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
  }
  network_profile {
    network_plugin = "azure"
    # Required for availability zones
    load_balancer_sku = "standard"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
    }
  }

  tags = {
    Environment = "Development"
  }

  agent_pool_profile {
    name = "agentpool"
    //    count               = var.agent_count
    vm_size             = "Standard_DS1_v2"
    min_count           = 1
    max_count           = 5
    enable_auto_scaling = true
    type                = "VirtualMachineScaleSets"
    max_pods            = 110
    os_type             = "Linux"
    os_disk_size_gb     = 30
    vnet_subnet_id      = azurerm_subnet.subnet.id
  }
}
resource "local_file" "kubeconfig" {
  content = azurerm_kubernetes_cluster.k8s.kube_config_raw
  filename = "config"
}
//resource "null_resource" "provision" {
//  triggers = {
//    config = azurerm_kubernetes_cluster.k8s.kube_config_raw
//  }
//  provisioner "local-exec" {
//    command = "kubectl -n kube-system create serviceaccount tiller --kubeconfig=config"
//  }
//  provisioner "local-exec" {
//    command = "kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller --kubeconfig=config"
//  }
//  provisioner "local-exec" {
//    command = "helm repo add stable https://kubernetes-charts.storage.googleapis.com --kubeconfig=config"
//  }
//  provisioner "local-exec" {
//    command = "helm repo update && helm fetch stable/prometheus-operator --kubeconfig=config --version 8.5.12"
//  }
//  provisioner "local-exec" {
//    command = "helm install prometheus-operator prometheus-operator-8.5.12.tgz --kubeconfig=config"
//  }
//}