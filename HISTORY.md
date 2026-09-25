# Project history and lessons learned

A timeline of how this NUC7i7BNH got to a stable macOS Sequoia install (2026-09-24 → 2026-09-25).

## 1. Attempt: macOS Tahoe 26.7 (abandoned)
**EFI:** [shuai620/NUC7i7BNH `OC_1.0.7_tahoe`](https://github.com/shuai620/NUC7i7BNH/tree/master/OC_1.0.7_tahoe), SMBIOS MacBookPro16,4.

**Symptom:** the verbose boot from the Tahoe USB installer stopped at
```
AppleFileSystemDriver: using boot-uuid
Still waiting for root device   (🚫 prohibited sign)
```
The log also showed repeated errors like this one:
```
Kext org.tw.CodecCommander - library kext com.apple.iokit.IOAudioFamily not found
```
Tahoe no longer ships IOAudioFamily. These errors were noise, not the cause of the hang.

**What was tried, without success:**
- Disabled CodecCommander, AirportItlwm, IO80211FamilyLegacy, IOSkywalkFamily, Sinetek-rtsx and FakePCIID. Replaced `slide=0` with `debug=0x100`, and turned on `DisableWatchDog`.
- Disabled `XhciPortLimit` and the two "laobamac Crack XHCIPortLimit 26.0+" kernel patches, because a valid USBMap.kext was present.
- Switched USBMap.kext's `IOProviderClass` from `AppleUSBXHCISPTLP` to `AppleUSBXHCIPCI`.
- Turned off Fast Boot and checked the other BIOS settings.

**Root cause:** the upstream README says Tahoe on this NUC *"require[s] OCLP-mod to patch AppleHDA and USB ports"*, and the author **upgraded from Sequoia**. A USB installer can't be root-patched, so a Tahoe installer on this machine can't see its own USB boot device.

**Decision:** stay on **macOS Sequoia**. It has native USB and audio, no root patches, SIP enabled, and security updates until about 2027. Apple has said Tahoe is the last macOS for Intel Macs anyway.

## 2. Making the Sequoia 15.8 USB installer
- `softwareupdate --fetch-full-installer --full-installer-version 15.8`. Version 15.7.1 was no longer offered. The download failed twice with "An internal error occurred" and resumed on retry.
- `createinstallmedia` failed twice on the ADATA stick ("Device not configured", then a "bus error"). It succeeded on the third try in a different port. → **The stick is unreliable.**
- The EFI was backed up before `createinstallmedia`. The EFI partition survived each rebuild anyway.
- The installer's first screen was in **Russian**, because of an old `prev-lang:kbd` value in NVRAM. That's fixed now (see the EFI changes in the README).

## 3. Sequoia install and the EFI switch
- First boot used the Tahoe EFI with the fixes above. Copying that EFI to the SSD led to a crash and no boot, from both the USB and the SSD. The USB's EFI turned out to be byte-identical to the working backup, so **Fast Boot** (skipping USB) and boot order were the real obstacles.
- **Fast Boot** had been turned on, which hid the F2 prompt. **The fix is the power button menu: hold 3 s → F2/F10.**
- Switched to the upstream **`OC_1.0.6_sequoia`** EFI (Macmini8,1) with unique serials. Result: a stable boot.
- Added **itlwm + HeliPort** for Wi-Fi, and chose it over native AirportItlwm, which needs an OCLP root patch and SIP partly off.
- Copied the EFI to the internal SSD's EFI partition (`disk0s1`) and removed the USB stick. The NUC boots from the SSD.

## 4. Tuning (over SSH)
- Quiet boot, no picker, OpenCore logging off.
- Disabled unused kexts: Sinetek-rtsx, CodecCommander, HibernationFixup.
- pmset: sleep off (sleep is broken on this build), Power Nap off, autorestart on, Wake on LAN on.
- Siri, analytics and automatic update downloads off. All UI animations off for remote use.
- Background audit: no third-party daemons. Built-in Apple apps are left alone, because the system volume is sealed.

## 5. Network notes
- The router is a Huawei **HG8145V5** (ISP-provided) with **no public IP (CGNAT)**, so port forwarding is impossible.
- **Tailscale** works behind CGNAT because it makes outbound connections. It's the recommended remote-access method.
- The HG8145V5 has **no Wake on LAN feature**. Remote power-on needs an always-on device on the LAN (Pi or old phone), a smart plug with BIOS "After Power Failure = Power On", or simply leaving the NUC on (about 1.4 W at idle).
- HeliPort Wi-Fi only connects **after login**. For headless or remote use, use **Ethernet**.

## 6. Benchmark and cooling
- Built small test tools (`tools/`) and ran a staged benchmark. **Run 1** (no external fans, case closed): stable, peak 84 °C.
- A stuck `rpcsvchost` (netlogon) process was found using 100% CPU after every boot, adding ~10 W at idle. It was disabled.
- Opened the case and added **2 × 120 mm 12 V fans** at 100%. **Run 2** (top blowing in) and **run 3** (flipped: bottom in, top out). The flipped layout was best: 7–12 °C cooler at light and medium load.
- **Run 4** repeated run 3 from a fully cooled idle and matched it within 0–2 °C, confirming the results are repeatable.
- Lowering the power limit was considered and rejected: the data showed the chip isn't heat-limited, and a lower PL1 would only cut speed.

## 7. Headless 24/7 host
- Ethernet with a DHCP reservation; an HDMI dummy plug for Screen Sharing.
- Tailscale built from source with Go (Homebrew has dropped Intel Macs), running as a boot-time daemon. SSH works from anywhere, behind CGNAT, before login.
- Screen Sharing rejected the correct password until *Remote Management* privileges were granted with `kickstart`.
- Hardening: key-only SSH, firewall and stealth mode, guest sharing off, Remote Apple Events off.

## Lessons learned
1. Read the EFI author's README first. It explained the Tahoe failure outright.
2. A "Still waiting for root device" error on a USB installer is a USB/root-device problem, not a kext-noise problem.
3. Always back up the EFI before `createinstallmedia` or any copy, and compare the copy with `diff -rq`.
4. Intel NUC: the power-button menu (hold 3 s) gets around Fast Boot.
5. Never reuse someone else's SMBIOS serials. Generate your own with `macserial`.
6. Cheap USB sticks fail under large sequential writes. Keep a known-good spare.
7. Check `top` after the first boots: one stuck system service can double idle temperature.
8. On macOS, *Remote Management* overrides Screen Sharing's user list. Grant privileges with `kickstart`.
