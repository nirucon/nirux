# Wi-Fi backends

The bar icon and **NIRUX Settings → Wi-Fi** open `nirulauncher --wifi`. Refresh
discovers nearby networks; typing filters SSIDs without scanning on each key.
Radio, disconnect and confirmed profile deletion are different operations.
Passwords stay out of command arguments and launcher history.

| Backend | Interface | Validation / limitations |
|---|---|---|
| NetworkManager | Native system D-Bus, saved-profile identity, scan/connect/disconnect/forget and WirelessEnabled | Used on real Arch/Void systems; active-session authorization applies. Existing enterprise profiles can be activated explicitly. |
| Standalone wpa_supplicant | Existing control socket through a root-owned restricted helper | Used with an existing DHCP service on Debian. NIRUX never starts a competing DHCP client. Profile saving is best-effort because ifupdown can start wpa_supplicant without a writable configuration file. |
| Standalone iwd | Native D-Bus device/station/network plus short-lived personal-secret agent | Native adapter/contract tests; live hardware combination not yet verified. Existing IP ownership is preserved. |
| ConnMan | Native D-Bus technology/service plus short-lived personal-secret agent | Native adapter/contract tests; live hardware combination not yet verified. ConnMan retains IP/DNS ownership. |

NIRUX does not install, enable or replace a network manager. NetworkManager's
own iwd/wpa_supplicant layer must not be independently controlled. Ambiguous or
unmanaged devices do not grant permission to take over networking. A daemon or
CLI merely being installed is not proof that it owns the adapter.

The standalone helper accepts only validated Wi-Fi requests; sudo never grants
arbitrary `wpa_cli` action scripts or a user-writable executable. Run `nirux update`
if a previous installation lacks this permission integration. Permission errors
must be shown in the selector rather than presenting an empty scan as success.

New enterprise configurations/certificate workflows and hidden networks on the
standalone iwd/ConnMan adapters are not advertised as universally supported. Use
an existing authenticated backend profile for unsupported methods. WEP is not
offered as a fallback; certificate validation must never be disabled. Association
alone is not proof of Internet connectivity, and captive portals are not opened
automatically.
