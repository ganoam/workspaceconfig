# Debug: black screen on resume (~50% of suspends)

Machine: Lenovo laptop, 12th-gen Intel + **NVIDIA RTX 3070 Ti (GA104M, Ampere)**, proprietary driver 595.99.02 (dkms), Ubuntu 26.04 / kernel 7.0.0-42, dwl (wlroots) + GNOME, `lock-and-suspend` = `wlock &; systemctl suspend`.

## Symptom

After `systemctl suspend` (deep), resume powers the display on but it stays black.
No keyboard/mouse response on screen, **VT switch also black**.
Power button still does a graceful shutdown → the *system* is alive; only display output is dead.

## Evidence trail

1. `lspci`: no Intel iGPU — internal panel wired directly to the dGPU, so every GPU power-state glitch lands on the display.
2. `/sys/power/mem_sleep` → `s2idle [deep]` — correct mode already.
3. NVIDIA suspend plumbing already right: `nvidia-suspend/resume/hibernate.service` enabled, `NVreg_PreserveVideoMemoryAllocations=1` active, `NVreg_TemporaryFilePath=/var` on disk, 18G free (VRAM ~8G).
4. Failed-resume window in `journalctl -b -2` — resume 06:12, power off 06:55 (dead screen in between):

```
06:12:52 systemd-suspend/nvidia-resume complete
06:14:15 gnome-shell: Added device '/dev/dri/card1' (nvidia-drm) using atomic mode setting
06:14:26 gnome-shell: GPU /dev/dri/card1 selected primary
06:17:37 kernel: [drm:nv_drm_atomic_apply_modeset_config] *ERROR* Failed to initialize semaphore for plane fence
06:17:37 kernel: [drm:nv_drm_atomic_commit] *ERROR* Failed to apply atomic modeset. Error code: -11
```

## Diagnosis

`nvidia-drm` fails its **atomic modeset** after resume — GPU alive, semaphore/fence path wedged → scanout dead → black screen. Intermittency + `-11` (EAGAIN) signature match the known Ampere-laptop failure where **runtime D3 power management** (`NVreg_DynamicPowerManagement=0x02`, PCI `power/control=auto`) collides with system suspend. No iGPU → no fallback rendering path → "screen on, black".

## Recommendations (all four)

| # | Fix | Status |
|---|---|---|
| 1 | Disable dGPU runtime PM | **applied** 2026-11-06 |
| 2 | Driver experiments (GSP off / rollback) | fallback if #1 fails |
| 3 | Fix lock-and-suspend race | **applied** 2026-11-06 |
| 4 | Diagnostics for next failure | preparedness |

### 1. Disable dGPU runtime PM

```bash
# /etc overrides /lib (pkg-update safe)
sudo tee /etc/modprobe.d/nvidia-disable-dpm.conf <<'EOF'
options nvidia NVreg_DynamicPowerManagement=0x00
EOF
sudo update-initramfs -u   # + reboot (module param)
```

Cost: slightly higher idle power draw.

### 2. Driver experiments (if #1 doesn't fix it)

```bash
options nvidia NVreg_EnableGpuFirmware=0   # add to same conf file
```

GSP firmware has its own resume-failure history on Ampere.
Journal shows 595.84→595.91.07→595.99.02 Sept–Nov — if failures correlate with an upgrade, `apt install nvidia-driver-580` (LTS branch) is a valid test.

### 3. lock-and-suspend race

`wlock &` can still be mapping its surface when the system freezes:

```bash
wlock &
sleep 1
systemctl suspend
```

### 4. Diagnostics for next failure

System stays alive — capture evidence *before* reboot:

```bash
# ssh in (install openssh-server while healthy), or power-button shutdown
journalctl -b -1 | grep -iE "nvidia|drm|xid" | grep -iE "error|fail"
sudo nvidia-bug-report.sh   # the report NVIDIA actually reads
```

## Status

#1 + #3 applied — pending observation over next suspend cycles.
If it recurs, move to #2.
