variable "subscription_id" {
  description = "Tu subscription_id de Azure (az account show --query id -o tsv)"
  type        = string
}

variable "student_name" {
  description = "Tu nombre/usuario, en minúsculas. Va en el FQDN público."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.student_name))
    error_message = "Solo minúsculas, números y guiones (3-20 caracteres)."
  }
}

variable "location" {
  description = "Región de Azure más cercana"
  type        = string
  default     = "northcentralus"
}

variable "vm_size" {
  description = "Tamaño de la VM. B2s alcanza; B2ms va holgado."
  type        = string
  default     = "Standard_B2as_v2"
}

variable "repo_url" {
  description = "TU fork del proyecto en GitHub (lo clona la VM al arrancar)"
  type        = string
}

variable "acme_email" {
  description = "Tu email (para el certificado HTTPS de Let's Encrypt)"
  type        = string
}

variable "pgadmin_password" {
  description = "Clave para pgAdmin y la terminal web"
  type        = string
  default     = "scoopers"
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Ruta a tu llave pública SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

