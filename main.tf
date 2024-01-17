terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
    features {} 
      subscription_id = $ARM_SUBSCRIPTION_ID
      tenant_id = $ARM_TENANT_ID
      client_id = $ARM_CLIENT_ID
      client_secret = $ARM_CLIENT_SECRET
}

resource "azurerm_virtual_network" "dev-vnet" {
    name = "dev-vnet"
    location = "East US"
    resource_group_name = azurerm_resource_group.Infra-test1.name
    address_space = [ "10.0.0.0/16" ]
    
    }

resource "azurerm_subnet" "subnet-1" {
    name = "subnet-1"
    resource_group_name = azurerm_resource_group.Infra-test1.name
    virtual_network_name = azurerm_virtual_network.dev-vnet.name
    address_prefixes = [ "10.0.1.0/24" ]
  
}

resource "azurerm_network_security_group" "infra-nsg" {
    name = "infra-nsg"
    location = azurerm_resource_group.Infra-test1.location
    resource_group_name = azurerm_resource_group.Infra-test1.name

    security_rule {
        name = "ssh_access"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }


  
}

resource "azurerm_subnet_network_security_group_association" "subnet1-infra-nsg-assoc" {
    subnet_id = azurerm_subnet.subnet-1.id
    network_security_group_id = azurerm_network_security_group.infra-nsg.id
  
}

resource "azurerm_public_ip" "vm-pub-ip" {
    name = "vm-pub-ip"
    resource_group_name = azurerm_resource_group.Infra-test1.name
    location = azurerm_resource_group.Infra-test1.location
    allocation_method = "Static"
}

resource "azurerm_network_interface" "vm-nic" {
    name = "vm_nic"
    resource_group_name = azurerm_resource_group.Infra-test1.name
    location = azurerm_resource_group.Infra-test1.location
    

    ip_configuration {
      name = "Internal"
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.subnet-1.id
      public_ip_address_id = azurerm_public_ip.vm-pub-ip.id
    }
  
}


resource "azurerm_linux_virtual_machine" "test-linux-vm01" {

    name = "test-linux-vm01"
    resource_group_name = azurerm_resource_group.Infra-test1.name
    location = azurerm_resource_group.Infra-test1.location
    size = "Standard_B1ls"
    admin_username =  var.username
    admin_password =  var.password
    network_interface_ids = [ azurerm_network_interface.vm-nic.id ]
    disable_password_authentication = false

   
    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    source_image_reference {
      publisher = "Oracle"
      offer = "Oracle-Linux"
      sku = "ol84-lvm-gen2"
      version = "latest"
    }

  
}

output "vm-public_ip_address" {
    value = azurerm_public_ip.vm-pub-ip.ip_address
}



