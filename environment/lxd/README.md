# LXD multi-node setup

```bash
# Inside the lab VM
lxc network create labnet ipv4.address=10.50.0.1/24 ipv4.nat=true ipv6.address=none
lxc profile create lab-node
lxc profile edit lab-node < profiles/lab-node.yaml
for n in node1 node2 node3; do lxc launch ubuntu:24.04 "$n" -p default -p lab-node; done
lxc list
```

Tear down: `for n in node1 node2 node3; do lxc delete -f "$n"; done`
