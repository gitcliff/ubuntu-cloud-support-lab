# 05 · Virtualization (15%)

| # | Lab | Key skills | Status |
|---|---|---|---|
| 01 | [Create a KVM guest from a cloud image](01-kvm-cloud-image) | virt-install, cloud-localds, virsh | worked example |
| 02 | VM won't start: "KVM not available" | kvm-ok, nested virt, `/dev/kvm` permissions | ☐ |
| 03 | Snapshot and roll back a broken VM | virsh snapshot-*, qcow2 backing files | ☐ |
| 04 | Guest is slow | virtio drivers, CPU pinning, `virsh domstats` | ☐ |

Note: Apple Silicon hosts can't nest KVM inside Multipass. Use the Terraform host or an x86 machine.

Core commands: `virsh`, `virt-install`, `qemu-img`, `kvm-ok`, `multipass`.
