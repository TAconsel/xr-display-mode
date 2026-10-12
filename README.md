# XR Display Mode

A small GTK 4 / libadwaita app for Linux that switches XREAL glasses between
2D and side-by-side (SBS) 3D, and sets their brightness. It talks to the
glasses' MCU directly over hidraw, so it needs no vendor software and no root.

- One-click **2D / 3D Side-by-side** toggle.
- Every display mode the glasses offer, with the current one selected.
- **Brightness** slider (levels 0–8, the same steps as the buttons on the
  glasses). Button presses are picked up within 2 s.
- The resolution and refresh rate the computer drives the glasses at, read
  from KScreen on KDE Plasma. This is how you get 90 Hz in plain 2D mode.
- Shows the glasses' name, serial and firmware, and follows hotplug.

Tested on an XREAL Air 2 (firmware 09.1.00.107) under KDE Plasma 6 on Wayland.
The Air, Air 2 Pro and Air 2 Ultra use the same protocol but are untested.

## Install

Needs Python 3, PyGObject, GTK 4 and libadwaita 1.7 or newer
(`python3-gi gir1.2-gtk-4.0 gir1.2-adw-1` on Debian/Ubuntu).
`kscreen-doctor` is optional and only used for the computer-output section.

```
sudo make install          # PREFIX=/usr/local by default
sudo udevadm control --reload && sudo udevadm trigger
```

The udev rule gives the logged-in user access to the glasses' hidraw nodes.
Replug the glasses once after installing it.

## Command line

```
xr-display-mode                     # open the window
xr-display-mode --list              # every mode, current one marked *
xr-display-mode --get
xr-display-mode --set sbs           # also: 2d, or a mode number
xr-display-mode --brightness [0-8]
```

## Display modes

| Mode | Glasses output |
|---|---|
| 1 | 2D 1920×1080; the computer picks 60, 90 or 120 Hz (reads back as 11 at 120 Hz) |
| 5 / 11 | 2D at 72 / 120 Hz only |
| 10 | 2D at 90 Hz; rejected (status 1) by Air 2 firmware 09.1.00.107 |
| 3 / 4 / 9 | SBS 3840×1080 at 60 / 72 / 90 Hz, 1920×1080 per eye |
| 8 | Half SBS: 1920×1080 at 60 Hz, 960 px per eye |

After a switch the glasses re-train the DisplayPort link and come back with
a new EDID. The compositor sees this as a hotplug and picks the new mode.

## Known issue: flicker after a software switch

On the Air 2 tested, switching modes from software leaves the glasses with
a PWM-like flicker. This happens at every refresh rate, and even when the
command re-sends the mode the glasses are already in. Switching with the
button on the glasses is clean, and a button switch also clears the flicker.

The flicker is inside the glasses. It survives a brightness change, a
DisplayPort link reset from the computer, and having no compositor effects
running. On the HID interface both paths look identical: the same panel
off/on events (`0x6c18` 00 → 01), with the same timing. The only difference
is the button-press report. The firmware's button handler seems to bring the
panel up differently from the host's `0x08` command, and no documented
command reproduces it. Until the official app's traffic is captured, use the
button for a flicker-free SBS.

## Protocol notes

The MCU is HID interface 4 (interface 0 on the Air 2 Ultra). Requests and
replies are 64-byte reports:

```
0xfd | crc32 (4) | length (2) | timestamp (8) | msgid (2) | reserved (5) | data
```

`length` counts itself through the end of the data, and the CRC-32 covers
those `length` bytes. A reply echoes the msgid, and its data starts with a
status byte (0 = ok).

| msgid | Meaning |
|---|---|
| 0x03 / 0x04 | Read / write brightness, 0–8 (higher values clamp to 8) |
| 0x07 / 0x08 | Read / write display mode |
| 0x15 | Serial number |
| 0x26 | MCU firmware version |
| 0x6c05 | Event: button pressed (physical and virtual button codes) |
| 0x6c18 | Event: panel off (00) / on (01) around a mode change |

The message IDs come from
[nrealAirLinuxDriver](https://gitlab.com/TheJackiMonster/nrealAirLinuxDriver)
and [ar-drivers-rs](https://github.com/badicsalex/ar-drivers-rs). The
brightness range, the mode behaviour and `0x6c18` were measured on hardware.
That driver also lists firmware-update and bootloader messages
(`0x3d`–`0x49`, `0x1100`+). Never send those by hand.
