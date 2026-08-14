output "mi_laboratorio" {
  description = "Tus accesos"
  value = {
    web      = "https://${azurerm_public_ip.lab.fqdn}"
    terminal = "https://${azurerm_public_ip.lab.fqdn}/terminal"
    pgadmin  = "https://${azurerm_public_ip.lab.fqdn}/pgadmin"
    metabase = "https://${azurerm_public_ip.lab.fqdn}/metabase"
    ssh      = "ssh azureuser@${azurerm_public_ip.lab.fqdn}"
  }
}

output "vm_name" {
  description = "Nombre de la VM (para encender/apagar)"
  value       = azurerm_linux_virtual_machine.lab.name
}

output "resource_group" {
  description = "Grupo de recursos (para encender/apagar)"
  value       = azurerm_resource_group.lab.name
}
