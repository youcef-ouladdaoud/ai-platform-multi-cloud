# Azure Network Resources
resource "azurerm_virtual_network" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "ai-platform-vnet"
  address_space       = [var.vpc_cidr]
  location            = var.region
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "public" {
  count                = var.cloud_provider == "azure" ? length(var.public_subnet_cidrs) : 0
  name                 = "ai-platform-public-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [var.public_subnet_cidrs[count.index]]
}

resource "azurerm_subnet" "private" {
  count                = var.cloud_provider == "azure" ? length(var.private_subnet_cidrs) : 0
  name                 = "ai-platform-private-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [var.private_subnet_cidrs[count.index]]
}

resource "azurerm_public_ip" "nat" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "ai-platform-nat-ip"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "ai-platform-nat"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = var.cloud_provider == "azure" ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = var.cloud_provider == "azure" ? length(var.private_subnet_cidrs) : 0
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

resource "azurerm_network_security_group" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "ai-platform-nsg"
  location            = var.region
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "8080", "11434"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
