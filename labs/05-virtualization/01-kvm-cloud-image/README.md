# Lab 01: Create a KVM guest from a cloud image

| | |
|---|---|
| Domain | virtualization |
| Difficulty | ★★☆ |
| Time | ~45 min |
| Environment | x86 host with `/dev/kvm` |

This is a **build** lab, not a break/fix one: you need to know how the happy path
works before you can support it.

## Steps
1. Check KVM: `kvm-ok`, `ls -l /dev/kvm`
2. Download the image:
   `wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img`
3. Create an overlay disk:
   `qemu-img create -f qcow2 -F qcow2 -b noble-server-cloudimg-amd64.img guest1.qcow2 10G`
4. Build a seed ISO from [user-data](user-data):
   `cloud-localds seed.iso user-data`
5. Install:
   ```bash
   virt-install --name guest1 --memory 1024 --vcpus 1 \
     --disk guest1.qcow2 --disk seed.iso,device=cdrom \
     --os-variant ubuntu24.04 --import --network network=default --noautoconsole
   ```
6. Find its IP: `virsh domifaddr guest1`, then SSH in.

## Questions to answer in your write-up
- What is a qcow2 backing file, and what happens if you delete the base image?
- Where does libvirt store the domain XML? (`virsh dumpxml guest1`)
- What does the `default` network do? (`virsh net-dumpxml default`)

## Clean up
```bash
virsh destroy guest1; virsh undefine guest1 --remove-all-storage
```
