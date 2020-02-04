
provider "azurerm" {
  version = "~>1.42"
    tenant_id       = "4ee2b3e6-08d2-4d50-bbcd-c1941394ffb8"
    subscription_id = "9a328c9e-11da-4a7d-ad88-62bf0136a083"
    client_id       = "76ff0bc5-3f17-4d08-990f-53a5525c8c01"
    client_secret   = "@_lo@fFac:n85Sw1NOo9dT[LCo11s.tu"
use_msi = "true"

}
variable "web_server_location" {}
variable "web_server_rg" {}
variable "environment" {}
variable "web_server_name" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_address_prefix" {}

locals {
  web_server_name   = "${var.environment == "production" ? "${var.web_server_name}-prd" : "${var.web_server_name}-dev"}"
  build_environment = "${var.environment == "production" ? "production" : "development"}"
}
resource "azurerm_resource_group" "web_server_rg"{
  name     = "${var.web_server_rg}"
  location = "${var.web_server_location}"
tags =  {
  environment   = "${local.build_environment}"
  }
}
resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  address_space       = ["${var.web_server_address_space}"]
}
resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = "${azurerm_resource_group.web_server_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.web_server_vnet.name}"
  address_prefix       = "${var.web_server_address_prefix}"
}

resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.web_server_name}-nic"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"

  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = "${azurerm_subnet.web_server_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}
resource "azurerm_public_ip" "web_server_public_ip" {
  name                         = "${var.web_server_name}-public-ip"
  location                     = "${var.web_server_location}"
  resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
  public_ip_address_allocation = "${var.environment == "production" ? "static" : "dynamic"}"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.web_server_name}-nsg"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}" 
}
resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.web_server_rg.name}" 
  network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}" 
}

resource "azurerm_virtual_machine" "web_server" {
  name                         = "${var.web_server_name}"
  location                     = "${var.web_server_location}"
  resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"  
  network_interface_ids        = ["${azurerm_network_interface.web_server_nic.id}"]
  vm_size                      = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.web_server_name}-os"    
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  os_profile {
    computer_name      = "${var.web_server_name}" 
    admin_username     = "vsudhagar"
    admin_password     = "Password@123"
  }

  os_profile_windows_config {
  }

}