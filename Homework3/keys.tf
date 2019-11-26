resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server_key" {
  key_name   = "hw_webserver_key"
  public_key = "${tls_private_key.server_key.public_key_openssh}"
}

resource "local_file" "server_key" {
  sensitive_content  = "${tls_private_key.server_key.private_key_pem}"
  filename           = "webserver.pem"
}
