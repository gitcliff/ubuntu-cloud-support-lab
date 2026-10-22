# Optional: cloud host for KVM labs

Use this only if your laptop can't do nested virtualisation (Apple Silicon Macs
can't run KVM-in-Multipass). It creates **one** AWS EC2 metal-capable
instance running Ubuntu 24.04 with the same cloud-init as the local VM.

> Cost warning: `c5.metal` or similar is expensive. Use `t3.large` for
> non-KVM labs, and **always** run `terraform destroy` when you finish.

```bash
cd environment/terraform
terraform init
terraform apply -var="key_name=my-keypair" -var="my_ip_cidr=$(curl -s ifconfig.me)/32"
terraform output ssh_command
terraform destroy
```
