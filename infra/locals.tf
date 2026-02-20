# Auto-detect your public IP
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

# Generate random password if not provided (alphanumeric only)
resource "random_password" "db_password" {
  length  = 16
  special = false
}

locals {
  # Use provided IP or auto-detected IP
  my_ip_cidr = var.my_ip != "" ? var.my_ip : "${trimspace(data.http.my_ip.response_body)}/32"
  
  # Use provided password or generated password
  db_password = var.db_password != "" ? var.db_password : random_password.db_password.result
}
