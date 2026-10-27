# Input settings

NIRUWM uses the system X11 keyboard layout by default. An explicit user choice is
stored in `~/.config/niruwm/input.toml` and applied by `niruwm-session`; the old
`KEYBOARD_LAYOUT` session override is still honoured when set.

Open **NIRUX Settings → Input devices**, run `nirulauncher --input`, or use
`niructl input`:

```sh
niructl input status [--json]
niructl input set-keyboard se
niructl input set-keyboard us intl
niructl input set-repeat 250 40
niructl input set-pointer natural on
niructl input set-pointer tap on
niructl input set-speed 0.2
niructl input reset
```

Keyboard layout and repeat settings use `setxkbmap` and `xset`. Pointer and
touchpad settings use the XInput `libinput` properties for natural scrolling,
tap-to-click and acceleration. Devices without those properties are reported as
unsupported rather than changed blindly; Synaptics-only controls are not
advertised. `nirux update` installs the `xinput` command required for pointer
settings.

Input settings are ordinary user configuration and survive NIRUX updates.
`reset` removes the NIRU overrides; the system defaults then apply at the next
login.
