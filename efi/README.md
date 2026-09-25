# EFI

`config.sanitized.plist` is the **exact config running on the NUC (2026-09-25)**, with the machine's identity removed:

| Key | In this file | What to use |
|---|---|---|
| `PlatformInfo → Generic → SystemSerialNumber`, `MLB` | `GENERATE-WITH-macserial` | `macserial -m Macmini8,1 -g -n 1` (from the OpenCore release's `Utilities/macserial`) |
| `PlatformInfo → Generic → SystemUUID` | `GENERATE-WITH-uuidgen` | `uuidgen` |
| `PlatformInfo → Generic → ROM` | `000000000000` | Your Ethernet MAC address, or 6 random bytes |
| `DataHub` / `PlatformNVRAM` serials | `REDACTED` | Unused, because `Automatic = true` makes OpenCore use `Generic` |

## Rebuild the full EFI
1. Download [shuai620/NUC7i7BNH `OC_1.0.6_sequoia/EFI`](https://github.com/shuai620/NUC7i7BNH/tree/master/OC_1.0.6_sequoia).
2. Add `itlwm.kext` v2.3.0 from [OpenIntelWireless/itlwm releases](https://github.com/OpenIntelWireless/itlwm/releases) to `EFI/OC/Kexts/`.
3. Replace `EFI/OC/config.plist` with `config.sanitized.plist`, and fill in your own serial numbers (see the table above).
4. Install [HeliPort](https://github.com/OpenIntelWireless/HeliPort/releases) in macOS to use Wi-Fi.

> ⚠️ Never commit a `config.plist` that contains your real serial, MLB, UUID or ROM.
