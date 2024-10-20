# Resource Group
resource "azurerm_resource_group" "azure_task" {
  name     = "lab-resource-group"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "azure_task" {
  name                = "lab-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azure_task.location
  resource_group_name = azurerm_resource_group.azure_task.name
}

# Subnet
resource "azurerm_subnet" "azure_task" {
  name                 = "lab-subnet"
  resource_group_name  = azurerm_resource_group.azure_task.name
  virtual_network_name = azurerm_virtual_network.azure_task.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "azure_task" {
  name                = "lab-nsg"
  location            = azurerm_resource_group.azure_task.location
  resource_group_name = azurerm_resource_group.azure_task.name
}

# Allow SSH Access
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix   = "*"
  network_security_group_name  = azurerm_network_security_group.azure_task.name
  resource_group_name          = azurerm_resource_group.azure_task.name
}

# Allow HTTPS Access
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "Allow-HTTPS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix   = "*"
  network_security_group_name  = azurerm_network_security_group.azure_task.name
  resource_group_name          = azurerm_resource_group.azure_task.name
}

# Allow ICMP
resource "azurerm_network_security_rule" "allow_icmp" {
  name                        = "Allow-ICMP"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix   = "*"
  network_security_group_name  = azurerm_network_security_group.azure_task.name
  resource_group_name          = azurerm_resource_group.azure_task.name
}

# Network Interfaces for VMs
resource "azurerm_network_interface" "azure_task" {
  count               = 2
  name                = "lab-nic-${count.index == 0 ? "alice" : "bob"}"
  location            = azurerm_resource_group.azure_task.location
  resource_group_name = azurerm_resource_group.azure_task.name

  ip_configuration {
    name                          = "ipconfig-${count.index == 0 ? "alice" : "bob"}"
    subnet_id                    = azurerm_subnet.azure_task.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "azure_task" {
  count               = 2
  name                = "lab-vm-${count.index == 0 ? "alice" : "bob"}"
  resource_group_name = azurerm_resource_group.azure_task.name
  location            = azurerm_resource_group.azure_task.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!" 
  network_interface_ids = [azurerm_network_interface.azure_task[count.index].id]
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "azure_task" {
  name                = "lab-public-ip"
  location            = azurerm_resource_group.azure_task.location
  resource_group_name = azurerm_resource_group.azure_task.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# Load Balancer
resource "azurerm_lb" "azure_task" {
  name                = "lab-lb"
  location            = azurerm_resource_group.azure_task.location
  resource_group_name = azurerm_resource_group.azure_task.name
  sku                 = "Basic"  

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.azure_task.id
  }
}

# Outputs
output "lb_ip_address" {
  value = azurerm_public_ip.azure_task.ip_address
}

output "vm_private_ip_addresses" {
  value = azurerm_network_interface.azure_task[*].private_ip_address
}
