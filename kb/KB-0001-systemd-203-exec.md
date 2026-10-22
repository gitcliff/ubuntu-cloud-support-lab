# KB-0001: systemd service fails with `status=203/EXEC`

**Applies to:** Ubuntu 22.04, 24.04
**Component:** systemd
**Last reviewed:** 2026-10-22

## Symptom
A service fails to start, and `systemctl status <unit>` shows:
```
Main process exited, code=exited, status=203/EXEC
```
The journal may also show `Permission denied` or `No such file or directory`.

## Cause
Exit code 203 means systemd could not **execute** the `ExecStart=` binary, so the
program itself never ran. Common causes:
- the file isn't executable (missing `+x`)
- the path is wrong or the file was removed
- the script has a bad shebang line or Windows (CRLF) line endings
- the filesystem is mounted `noexec`

## Resolution
1. Find the configured command: `systemctl cat <unit> | grep ExecStart`
2. Check the file: `ls -l <path>` and `head -1 <path>`
3. Fix whatever is wrong, e.g. `sudo chmod 755 <path>`
4. `sudo systemctl daemon-reload` (only if you edited the unit file)
5. `sudo systemctl restart <unit>`

## Verification
```bash
systemctl is-active <unit>
journalctl -u <unit> -n 20 --no-pager
```

## Additional information
- `man systemd.exec`, section "PROCESS EXIT CODES"
- Lab: [labs/01-linux/01-systemd-failed-service](../labs/01-linux/01-systemd-failed-service)
