# Ubuntu Cloud Support Lab

A hands-on learning project focused on Ubuntu Linux troubleshooting, cloud infrastructure
fundamentals, incident investigation, and technical support documentation.

The goal is to develop practical skills relevant to Linux and cloud support engineering
through reproducible labs and evidence-based troubleshooting.

Every lab follows the same loop a real support engineer works through:

```
Break it  →  Observe symptoms  →  Diagnose  →  Fix  →  Prevent  →  Write it up (KB + ticket reply)
```

## Objectives

- Diagnose common Linux service and system failures.
- Investigate problems using logs, system utilities, and configuration files.
- Troubleshoot networking, containers, and storage.
- Practise safe remediation and recovery verification.
- Write reusable troubleshooting guides.
- Develop professional technical support communication.
- Automate selected diagnostic tasks.

## Lab Methodology

Each lab follows a consistent workflow:

1. Reproduce a problem safely.
2. Collect diagnostic evidence.
3. Identify the root cause.
4. Apply a corrective action.
5. Verify recovery.
6. Document the findings.
7. Test cleanup and rollback.

Only mark a lab complete after executing and verifying it.

## Skills map

| Domain | Weight | Typical job description phrase | Where to look |
|---|---|---|---|
| Linux | 30% | "Troubleshoot Ubuntu systems: systemd, packages, performance, logs" | [labs/01-linux](labs/01-linux) |
| Networking | 20% | "Diagnose DNS, routing, firewall and connectivity problems" | [labs/02-networking](labs/02-networking) |
| Containers | 20% | "Support LXD, Docker and Kubernetes (MicroK8s) workloads" | [labs/03-containers](labs/03-containers) |
| Storage | 15% | "LVM, filesystems, RAID, NFS, Ceph" | [labs/04-storage](labs/04-storage) |
| Virtualization | 15% | "KVM/libvirt, cloud images, Multipass" | [labs/05-virtualization](labs/05-virtualization) |
| Scripting & tooling | across all | "Automate data collection; Bash, testing, CI" | [tools/](tools) |
| Customer communication | across all | "Write clear, empathetic technical responses" | [support-cases/](support-cases), [kb/](kb) |

## Labs

| Lab | Focus | Status |
|---|---|---|
| [01. Systemd service failure](labs/01-linux/01-systemd-failed-service) | Service management, logs, configuration troubleshooting | In progress |
| [02. Disk full but df says space is free](labs/01-linux/02-disk-full-df-free) | Deleted-but-open files, lsof, inode exhaustion | Ready to run |
| [03. Broken apt / dpkg state](labs/01-linux/03-broken-apt-dpkg) | dpkg --configure -a, stale locks, held packages | Ready to run |

## Repository Structure

```
environment/      Reproducible lab VMs (Multipass, LXD)
labs/             Break/fix exercises, one folder per domain
tools/            ubuntu-diag.sh (a lightweight sosreport) + bats tests
kb/               Knowledge-base articles, one per completed lab
support-cases/    Simulated support incidents and written responses
templates/        Copy these when you add a lab, KB article or case
.github/          CI: shellcheck + bats on every push
```

- `labs/` — practical troubleshooting exercises.
- `kb/` — reusable knowledge-base articles.
- `support-cases/` — simulated support incidents.
- `CLAUDE.md` — project-specific AI assistant instructions.

## Environment

The initial labs are designed for an Ubuntu virtual machine running in UTM on an Apple
Silicon Mac. Some advanced virtualization and cloud exercises may require a separate Linux
host or cloud environment.

```bash
# 1. Install Multipass (macOS: brew install --cask multipass; Ubuntu: sudo snap install multipass)
# 2. Launch the lab VM with the lab's cloud-init
multipass launch 24.04 --name lab --cpus 2 --memory 4G --disk 20G \
  --cloud-init environment/multipass/cloud-init.yaml
# 3. Mount this repo into the VM and get a shell
multipass mount . lab:/home/ubuntu/lab
multipass shell lab
# 4. Run the diagnostic tool
sudo /home/ubuntu/lab/tools/ubuntu-diag.sh -o /tmp
```

Multi-node labs (networking, Ceph) use LXD; see [environment/lxd/profiles](environment/lxd/profiles).

## Study plan (12 weeks, about 6–8 h a week)

| Week | Focus | Deliverables |
|---|---|---|
| 1 | Set up the environment, read the templates | Lab VM running, `ubuntu-diag.sh` runs |
| 2–4 | 01-linux | 4 labs, 4 KB articles, 2 support cases |
| 5–6 | 02-networking | 3 labs, 3 KB articles, 1 support case |
| 7–8 | 03-containers | 3 labs, 3 KB articles, 1 support case |
| 9 | 04-storage | 2 labs, 2 KB articles |
| 10 | 05-virtualization | 2 labs, 2 KB articles |
| 11 | Tooling | Add one new collector to `ubuntu-diag.sh` per domain, with tests |
| 12 | Polish | Tidy this README, record a 5-min demo, pin the repo |

## Progress tracker

Tick items off as you finish them.

- [ ] Environment working (Multipass + LXD)
- [ ] 01-linux: 1 / 6 labs (lab 01 in progress)
- [ ] 02-networking: 0 / 5 labs
- [ ] 03-containers: 0 / 5 labs
- [ ] 04-storage: 0 / 4 labs
- [ ] 05-virtualization: 0 / 4 labs
- [ ] `ubuntu-diag.sh` has one collector per domain
- [ ] 10+ KB articles
- [ ] 5+ support cases
- [ ] CI is green

## Scope and Limitations

This is an educational portfolio, not a production support environment. Simulated incidents
are explicitly labeled, and technical results are documented only after verification.

## Conventions

- Each lab has its own `README.md` with **Scenario → Break → Symptoms → Diagnose → Fix → Prevent → References**.
- Each lab also includes `CHECKLIST.md` (completion criteria) and `notes.md` (working journal).
- Break steps are scripted (`break.sh`), so you can reset a lab and practise again without peeking at the fix.
- Commands that change the system are run **inside the lab VM only**, never on your host.

## Long-term roadmap

Linux administration, networking, containers, storage, KVM/libvirt, introductory OpenStack
troubleshooting, and diagnostic automation. The repository will grow incrementally as each
lab is implemented, tested, and documented.
