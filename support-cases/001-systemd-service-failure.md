# Support Case 0001: Reporting Service Down After Reboot

**Case type:** Simulated educational exercise<br>
**Status:** Example; based on the systemd lab, not a real customer engagement<br>
**Component:** `reportd` systemd service<br>
**Environment:** Ubuntu 24.04 LTS virtual machine<br>
**Opened:** 2026-10-22 08:14 UTC<br>
**SLA first response:** 2 h

## 1. Customer-Reported Issue

> Hi, after patching last night our reporting service is not running anymore.
> We didn't change anything. It's urgent, management needs the reports by noon.
> — Sam, Ops team

## 2. Impact and Severity

**Assumed impact:** Reports are delayed, but nothing is lost. Management needs
the reports by noon.

**Severity:** 2 (degraded service).

## 3. Initial Information Requested

The first response requested these diagnostic outputs:

```bash
sudo systemctl status reportd --no-pager
sudo journalctl -u reportd -b --no-pager -n 50
sudo systemctl cat reportd
```

The customer was also offered the diagnostic script (`sudo ./ubuntu-diag.sh`)
and asked to attach its tarball. A reply was promised within 30 minutes of
receiving the output.

## 4. Investigation

The investigation considered whether a package update or a deployment occurred
alongside the reported patching. The service status, journal, and unit
configuration were requested for review.

The issue was reproduced in lab `01-linux/01`: the service reported
`status=203/EXEC`, indicating systemd could not execute the configured program.

## 5. Root Cause

In the lab reproduction, `/opt/reportd/reportd` had mode `-rw-r--r--` (`0644`),
so it did not have execute permission. The deployment that replaced the file is
the suspected cause; the available case notes do not establish that the OS
patches caused the failure.

## 6. Resolution

The resolution response instructed the customer to restore execute permission
and restart the service:

```bash
sudo chmod 755 /opt/reportd/reportd
sudo systemctl restart reportd
systemctl is-active reportd   # should print "active"
```

## 7. Verification

The following checks were provided to verify recovery:

```bash
systemctl is-active reportd
systemctl status reportd --no-pager
journalctl -u reportd -b --no-pager -n 10
```

**Result:** The case notes do not include the command output or customer
confirmation. The case remains open until the customer confirms that reports
are running again.

## 8. Customer-Facing Response

### First response

> Hi Sam,
>
> Thanks for reaching out. I understand the reports are needed by noon, so I'm
> treating this as a priority.
>
> To find the cause quickly, could you run the following and paste the output?
>
> ```
> sudo systemctl status reportd --no-pager
> sudo journalctl -u reportd -b --no-pager -n 50
> sudo systemctl cat reportd
> ```
>
> If it's easier, you can run our diagnostic script (`sudo ./ubuntu-diag.sh`) and
> attach the tarball it creates.
>
> I'll reply within 30 minutes of receiving the output.

### Resolution response

> Hi Sam,
>
> Thanks for the output. The service fails with `status=203/EXEC`, which means
> systemd couldn't run `/opt/reportd/reportd` because the file has lost its
> execute permission (it's `-rw-r--r--`). This is most likely from last night's
> deployment, which replaced the file, rather than from the OS patches.
>
> **To fix:**
>
> ```
> sudo chmod 755 /opt/reportd/reportd
> sudo systemctl restart reportd
> systemctl is-active reportd   # should print "active"
> ```
>
> **To prevent a repeat:** set the file mode explicitly in your deployment tooling
> (e.g. `mode: "0755"` in Ansible), and consider an alert on `systemctl --failed`.
>
> More detail: KB-0001. I'll keep this case open until you confirm the reports are
> running again.

## 9. Prevention and Follow-up

- Set the file mode explicitly in deployment tooling (for example, `mode: "0755"` in Ansible).
- Consider an alert on `systemctl --failed`.
- Keep the case open until the customer confirms the reports are running again.
- Refer to KB-0001 for more detail.

## 10. Lessons Learned

- Customers often say "nothing changed". Ask what _did_ happen around that time.
- Ask for exact commands, not "send logs".

**Disclosure:** This is a simulated support case created for educational and
portfolio purposes. It is not a real customer engagement.
