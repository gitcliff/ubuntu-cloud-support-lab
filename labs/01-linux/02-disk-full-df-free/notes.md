# Lab 02 working notes — Disk full but `df` says space is free

**Environment:** Ubuntu 24.04 LTS

Fill in each section as you work through the lab. Paste actual command output —
do not summarise or paraphrase it.

---

## Step 1 — Reproduce the failure

```bash
sudo bash scripts/break.sh
```

Output:
```
cliff@cliff:~$ sudo bash break2.sh 
[sudo] password for cliff: 
Sorry, try again.
[sudo] password for cliff: 
Created symlink /etc/systemd/system/multi-user.target.wants/loggen.service \u2192 /etc/systemd/system/loggen.service.
Lab broken.
  The operator deleted /opt/loggen/app.log to free space.
  The loggen service is still running and holds the file open.

  Start investigating with:
    ls /opt/loggen/
    du -sh /opt/loggen/

```

---

## Step 2 — Observe symptoms

```bash
ls -lh /opt/loggen/
```
```
cliff@cliff:~$ ls -lh /opt/loggen/
total 4.0K
-rwxr-xr-x 1 root root 191 Oct 23 10:35 loggen
cliff@cliff:~$ 

```

```bash
du -sh /opt/loggen/
```
```
cliff@cliff:~$ du -sh /opt/loggen/
8.0K	/opt/loggen/

```

```bash
df -h .
```
```
cliff@cliff:~$ df -h 
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              391M  2.1M  389M   1% /run
efivarfs                           256K   17K  240K   7% /sys/firmware/efi/efivars
/dev/mapper/ubuntu--vg-ubuntu--lv   16G   14G  1.2G  93% /
tmpfs                              2.0G     0  2.0G   0% /dev/shm
tmpfs                              5.0M  8.0K  5.0M   1% /run/lock
/dev/vda2                          2.0G  210M  1.6G  12% /boot
/dev/vda1                          1.1G  6.4M  1.1G   1% /boot/efi
tmpfs                              391M  136K  391M   1% /run/user/1000

```

Observations:
- `app.log` present in listing? Yes / No > No
- `du` reports
- `df` usage
- Gap between `du` and `df`? Yes / No

---

## Step 3 — Diagnose

### lsof +L1

```bash
sudo lsof +L1
```

```
cliff@cliff:~$ sudo lsof +L1
lsof: WARNING: can't stat() fuse.gvfsd-fuse file system /run/user/1000/gvfs
      Output information may be incomplete.
lsof: WARNING: can't stat() fuse.portal file system /run/user/1000/doc
      Output information may be incomplete.
COMMAND     PID  USER   FD   TYPE DEVICE SIZE/OFF NLINK   NODE NAME
pipewire   1679 cliff   36u   REG    0,1     2312     0     95 /memfd:pipewire-memfd:flags=0x0000000f,type=2,size=2312 (deleted)
pipewire   1679 cliff   39u   REG    0,1     2312     0     96 /memfd:pipewire-memfd:flags=0x0000000f,type=2,size=2312 (deleted)
pipewire   1679 cliff   47u   REG    0,1     2312     0   1133 /memfd:pipewire-memfd:flags=0x0000000f,type=2,size=2312 (deleted)
pipewire   1679 cliff   49u   REG    0,1     2312     0   1134 /memfd:pipewire-memfd:flags=0x0000000f,type=2,size=2312 (deleted)
pipewire   1679 cliff   51u   REG    0,1     2312     0   1135 /memfd:pipewire-memfd:flags=0x0000000f,type=2,size=2312 (deleted)
gnome-she  1848 cliff   14u   REG    0,1        0     0   1142 /memfd:allocation fd (deleted)
gnome-she  1848 cliff   33u   REG    0,1    68405     0   1144 /memfd:mutter-shared (deleted)
gnome-she  1848 cliff   34u   REG    0,1      480     0    102 /memfd:mutter-shared (deleted)
gnome-she  1848 cliff   46r   REG  252,0       64     0 917863 /home/cliff/.local/share/gvfs-metadata/root (deleted)
gnome-she  1848 cliff   47r   REG  252,0    32768     0 931740 /home/cliff/.local/share/gvfs-metadata/root-ccc78a10.log (deleted)
gnome-she  1848 cliff   67u   REG    0,1 67108864     0   1158 /memfd:pulseaudio (deleted)
gnome-she  1848 cliff   82u   REG    0,1 67108864     0    181 /memfd:pulseaudio (deleted)
gsd-color  1953 cliff    9u   REG    0,1  2356992     0   1159 /memfd:wayland-cursor (deleted)
gsd-keybo  1967 cliff    9u   REG    0,1  2356992     0    120 /memfd:wayland-cursor (deleted)
gsd-media  1969 cliff    9u   REG    0,1  2356992     0    118 /memfd:wayland-cursor (deleted)
gsd-media  1969 cliff   16u   REG    0,1 67108864     0    124 /memfd:pulseaudio (deleted)
gsd-power  1970 cliff    9u   REG    0,1  2356992     0   1160 /memfd:wayland-cursor (deleted)
gsd-wacom  1980 cliff    9u   REG    0,1  2356992     0    121 /memfd:wayland-cursor (deleted)
ibus-exte  2091 cliff    9u   REG    0,1  2356992     0    119 /memfd:wayland-cursor (deleted)
tracker-m  2238 cliff    9u   REG    0,1        0     0   1167 /memfd:extract-persistent-storage (deleted)
tracker-m  2238 cliff   70u   REG    0,1       22     0   1210 /memfd:extract-persistent-storage (deleted)
xdg-deskt  2259 cliff   10u   REG    0,1     2304     0    125 /memfd:wayland-cursor (deleted)
gsd-xsett  2304 cliff    4u   REG    0,1        0     0   1175 /memfd:allocation fd (deleted)
xdg-deskt  2351 cliff   10u   REG    0,1  2356992     0   1176 /memfd:wayland-cursor (deleted)
mutter-x1  2370 cliff    4u   REG    0,1        0     0    129 /memfd:allocation fd (deleted)
evolution  2389 cliff    9u   REG    0,1  2356992     0    130 /memfd:wayland-cursor (deleted)
gnome-cal  2531 cliff   11u   REG    0,1     2304     0    138 /memfd:wayland-cursor (deleted)
gnome-ter  2672 cliff    9u   REG    0,1  2356992     0   1202 /memfd:wayland-cursor (deleted)
gnome-ter  2672 cliff   15u   REG    0,1 67108864     0    147 /memfd:pulseaudio (deleted)
gnome-ter  2672 cliff   19u   REG  252,0        0     0 131131 /tmp/#131131 (deleted)
update-no  2743 cliff   10u   REG    0,1  2356992     0    158 /memfd:wayland-cursor (deleted)
firefox    4700 cliff    9u   REG    0,1  2356992     0   1348 /memfd:wayland-cursor (deleted)
firefox    4700 cliff   22u   REG    0,1        0     0   2317 /memfd:allocation fd (deleted)
firefox    4700 cliff   43r   REG    0,1   156120     0    297 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   46r   REG  252,0       64     0 917863 /home/cliff/.local/share/gvfs-metadata/root (deleted)
firefox    4700 cliff   47r   REG  252,0    32768     0 931740 /home/cliff/.local/share/gvfs-metadata/root-ccc78a10.log (deleted)
firefox    4700 cliff   48r   REG    0,1  1048576     0   1358 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   51r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   58r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   59r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   60r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   61r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   62r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   64r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   65r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   66r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   67u   REG    0,1 67108864     0   1158 /memfd:pulseaudio (deleted)
firefox    4700 cliff   68r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   69r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   70r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   71r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   77r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   78r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   82u   REG    0,1 67108864     0    181 /memfd:pulseaudio (deleted)
firefox    4700 cliff   98r   REG    0,1   899856     0    643 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff   99r   REG    0,1   899856     0    643 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff  132u   REG    0,1  5280792     0   6065 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff  134u   REG    0,1 67108864     0   3232 /memfd:pulseaudio (deleted)
firefox    4700 cliff  139u   REG    0,1  5280792     0   6064 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff  143u   REG    0,1  1739320     0    651 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff  153u   REG    0,1  1739320     0   1836 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff  156r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
firefox    4700 cliff  170u   REG    0,1     4096     0   1426 /memfd:mozilla-ipc (deleted)
crashhelp  4770 cliff   46r   REG  252,0       64     0 917863 /home/cliff/.local/share/gvfs-metadata/root (deleted)
crashhelp  4770 cliff   47r   REG  252,0    32768     0 931740 /home/cliff/.local/share/gvfs-metadata/root-ccc78a10.log (deleted)
crashhelp  4770 cliff   67u   REG    0,1 67108864     0   1158 /memfd:pulseaudio (deleted)
crashhelp  4770 cliff   82u   REG    0,1 67108864     0    181 /memfd:pulseaudio (deleted)
Socket     4851 cliff   22r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   13r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   24r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   27r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   28r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   29r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   30r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   31r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   32r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   33r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   34r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   35r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   36r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   37r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   38r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   39r   REG    0,1   899856     0    643 /memfd:mozilla-ipc (deleted)
WebExtens  4869 cliff   46r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
RDD\x20Pr  4878 cliff   22r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff    4r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   24r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   25r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   26r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   27r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   28r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   29r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   30r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   31r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   32r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   33r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   34r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   35r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   36r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   39u   REG    0,1    65536     0   1369 /memfd:mozilla-ipc (deleted)
Privilege  4916 cliff   40r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Utility    5427 cliff   22r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff    4r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   12r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   24r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   25r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   26r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   27r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   28r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   29u   REG    0,1    65536     0   6304 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   30r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   31r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   32r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   33r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   34r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   35r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   36r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   45r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   5449 cliff   49u   REG    0,1   102400     0   4522 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   23r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   24r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   26r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   27r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   28r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   29r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   30r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   31r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   32r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   33r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   34r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   35r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   37r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   38r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   41r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   5610 cliff   44r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   13r   REG    0,1   899856     0    643 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   23r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   24r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   26r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   27r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   28r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   29r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   30r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   31r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   33r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   34r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   35r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   36r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   37r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   38r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   39r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Isolated   5994 cliff   41r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   13r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   23r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   24r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   26r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   27r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   28r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   29r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   30r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   32r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   33r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   34r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   35r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   36r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   37r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   38r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   6433 cliff   41r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   24r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   25r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   27r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   28r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   30r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   31r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   33r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   34r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   36r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   37r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   38r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   39r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   40r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   43r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   6463 cliff   51r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   24r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   25r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   27r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   28r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   30r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   31r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   32r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   34r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   35r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   36r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   37r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   38r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   39r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   40r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   7950 cliff   47r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   13r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   23r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   26r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   27r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   28r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   29r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   30r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   31r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   32r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   33r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   34r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   35r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   36r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   37r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   38r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   7975 cliff   42r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff    4r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   15r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   24r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   25r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   26r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   27r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   28r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   29r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   31r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   32r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   33r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   34r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   35r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   36r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Isolated   8202 cliff   37r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   23r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   26r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   27r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   28r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   29r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   30r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   31r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   32r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   33r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   34r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   35r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   36r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   37r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   38r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   39r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Web\x20Co 11507 cliff   42r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   24r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   27r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   28r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   29r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   30r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   31r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   32r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   33r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   34r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   35r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   36r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   37r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   38r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   39r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Web\x20Co 15182 cliff   40r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   23r   REG    0,1   286762     0   1360 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   24r   REG    0,1   460800     0   1359 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   27r   REG    0,1     7418     0   1352 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   28r   REG    0,1      226     0   1353 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   29r   REG    0,1     6190     0   1354 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   30r   REG    0,1     2172     0   1355 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   31r   REG    0,1     2356     0   1356 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   32r   REG    0,1    68240     0    301 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   33r   REG    0,1    24560     0    302 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   34r   REG    0,1      170     0    303 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   35r   REG    0,1     2748     0    304 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   36r   REG    0,1     1488     0    305 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   37r   REG    0,1    24584     0    306 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   38r   REG    0,1    11822     0    307 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   39r   REG    0,1      182     0    300 /memfd:mozilla-ipc (deleted)
Web\x20Co 18625 cliff   40r   REG    0,1    14116     0    688 /memfd:mozilla-ipc (deleted)
gjs       19025 cliff   10u   REG    0,1  2356992     0   6015 /memfd:wayland-cursor (deleted)
bash      19583  root    3w   REG  252,0    95642     0 131134 /opt/loggen/app.log (deleted)
sleep     24644  root    3w   REG  252,0    95642     0 131134 /opt/loggen/app.log (deleted)
cliff@cliff:~$ 

```

Key row I found:
```
bash      19583  root    3w   REG  252,0    95642     0 131134 /opt/loggen/app.log (deleted)
sleep     24644  root    3w   REG  252,0    95642     0 131134 /opt/loggen/app.log (deleted)
cliff@cliff:~$ 

```

PID: 19583
FD number: 3  (the `w` is the access mode — write — not part of the number)
File size shown: 95642 bytes (~93 KB)

### Inspect via /proc

```bash
sudo ls -la /proc/<pid>/fd/
```
```
cliff@cliff:~$ sudo ls -la /proc/19583/fd/
total 0
dr-x------ 2 root root  5 Oct 23 10:35 .
dr-xr-xr-x 9 root root  0 Oct 23 10:35 ..
lr-x------ 1 root root 64 Oct 23 10:35 0 -> /dev/null
lrwx------ 1 root root 64 Oct 23 10:35 1 -> 'socket:[131661]'
lrwx------ 1 root root 64 Oct 23 10:35 2 -> 'socket:[131661]'
lr-x------ 1 root root 64 Oct 23 10:44 255 -> /opt/loggen/loggen
l-wx------ 1 root root 64 Oct 23 10:35 3 -> '/opt/loggen/app.log (deleted)'

```

```bash
sudo stat /proc/<pid>/fd/<fdnumber>
```
```
cliff@cliff:~$ sudo stat /proc/19583/fd/3
  File: /proc/19583/fd/3 -> /opt/loggen/app.log (deleted)
  Size: 64        	Blocks: 0          IO Block: 1024   symbolic link
Device: 0,25	Inode: 131657      Links: 1
Access: (0300/l-wx------)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-10-23 10:35:45.076148267 +0000
Modify: 2026-10-23 10:35:45.075148270 +0000
Change: 2026-10-23 10:35:45.075148270 +0000
 Birth: -
cliff@cliff:~$ 

```

### My hypothesis

The `loggen` service opened `/opt/loggen/app.log` with a persistent write file
descriptor (`exec 3>>`) when it started. The `rm` command removed the directory
entry for the file, so `ls` and `du` no longer see it. However, the kernel has not
freed the underlying inode (131134 on device 252,0) or its disk blocks because PID
19583 (bash/loggen) still holds fd 3 open in write mode — confirmed by both
`lsof +L1` and `/proc/19583/fd/3 → /opt/loggen/app.log (deleted)`.

The 95,642 bytes allocated to that inode are still counted by `df` as used space.
Restarting or stopping the `loggen` service will close fd 3, drop the last
reference to the inode, and allow the kernel to free the blocks.

---

## Step 4 — Root cause

`loggen` (PID 19583, bash) opened `/opt/loggen/app.log` at startup via `exec 3>>`
and kept that file descriptor open for the lifetime of the process. When the
operator ran `rm /opt/loggen/app.log`, the directory entry was removed but the
kernel preserved inode 131134 and its allocated blocks because the open fd count
was still greater than zero.

Two processes held fd 3 to that inode: the parent bash process (PID 19583) and its
child `sleep` (PID 24644), which inherited the fd. Both showed the same inode
number (131134) and the same file size (95,642 bytes) in `lsof +L1`, confirming
they both reference the same underlying data.

`df` reports block usage at the filesystem level and correctly counted those blocks
as allocated. `ls` and `du` only traverse directory entries and therefore reported
the file as gone. The gap between the two tools was the diagnostic signal.

The fix is to stop or restart the `loggen` service, which closes fd 3 in both
processes, drops the inode's open-fd count to zero, and triggers the kernel to free
the blocks.

---

## Step 5 — Fix

```bash
sudo systemctl restart loggen
```

Post-restart check:
```bash
sudo lsof +L1 | grep loggen
```
```
cliff@cliff:~$ sudo lsof +L1 | grep loggen
lsof: WARNING: can't stat() fuse.gvfsd-fuse file system /run/user/1000/gvfs
      Output information may be incomplete.
lsof: WARNING: can't stat() fuse.portal file system /run/user/1000/doc
      Output information may be incomplete.

```

```bash
ls -lh /opt/loggen/app.log
```
```
cliff@cliff:~$ ls -lh /opt/loggen/app.log
-rw-r--r-- 1 root root 21K Oct 23 11:05 /opt/loggen/app.log
cliff@cliff:~$ 

```

```bash
df -h /opt/loggen
```
```
cliff@cliff:~$ df -h /opt/loggen
Filesystem                         Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv   16G   14G  1.2G  93% /
cliff@cliff:~$ 

```

---

## Step 6 — Bonus: inode check

```bash
df -i /opt/loggen
```
```
cliff@cliff:~$ df -i /opt/loggen
Filesystem                         Inodes  IUsed  IFree IUse% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv 1015808 330535 685273   33% /
cliff@cliff:~$ 


```

```Notes on what the IUse% value means here:
The root filesystem has 1,015,808 total inodes. 330,535 are in use (33%) and
685,273 are free (67%). IUse% at 33% is healthy — no inode exhaustion here.

Inode exhaustion would show IUse% at or near 100% while `df -h` still shows
available block space. In that state you cannot create new files or directories
even though the disk appears to have room. Common causes are large numbers of
small files: mail queues, session temp files, or a logging system that creates
one file per event. The fix is to delete many small files, not large ones.
```
---

## Step 7 — Reset

```bash
sudo bash scripts/reset.sh
```

Confirmed clean:
- `systemctl status loggen` 
- `ls /opt/loggen` 

---

## Key commands learned

| Command | Purpose |
|---|---|
| `lsof +L1` | List open files whose link count < 1 (deleted but still open) |
| `ls -la /proc/<pid>/fd/` | Inspect all file descriptors held by a process |
| `truncate -s 0 /proc/<pid>/fd/<n>` | Zero out a deleted-but-open file without restarting the process |
| `df -i` | Show inode usage (vs. block usage shown by default `df -h`) |
| `du -sh <dir>` | Report actual disk usage of a directory tree |

---

## Related

- KB article: [KB-0002-disk-full-deleted-open-files.md](../../../kb/KB-0002-disk-full-deleted-open-files.md)
- Support case: [0002-disk-full-after-deleting-logs.md](../../../support-cases/0002-disk-full-after-deleting-logs.md)
