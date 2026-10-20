#!/usr/bin/env python3
"""Verify that every built-in terminal palette has readable contrast."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
PALETTES = ROOT / "terminal" / "palettes"


def lum(hex_value: str) -> float:
    rgb = [int(hex_value[i : i + 2], 16) / 255.0 for i in (0, 2, 4)]

    def channel(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * channel(rgb[0]) + 0.7152 * channel(rgb[1]) + 0.0722 * channel(rgb[2])


def contrast(a: str, b: str) -> float:
    high, low = sorted((lum(a), lum(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def main() -> int:
    failed = False
    for path in sorted(PALETTES.glob("*.env")):
        values = {}
        for line in path.read_text().splitlines():
            if "=" in line and not line.startswith("#"):
                key, value = line.split("=", 1)
                values[key.strip()] = value.strip().strip('"')
        bg = values["NIRU_TERM_BG"]
        fg = values["NIRU_TERM_FG"]
        checks = [
            ("foreground", fg, 7.0),
            ("muted", values["NIRU_TERM_MUTED"], 4.5),
            ("border", values["NIRU_TERM_BORDER"], 1.2),
            ("focus", values["NIRU_TERM_FOCUS"], 2.5),
        ]
        selection = values["NIRU_TERM_SELECTION"]
        selection_ratio = contrast(fg, selection)
        if selection_ratio < 4.5:
            print(
                f"{path.name}: selection foreground contrast {selection_ratio:.2f} < 4.5"
            )
            failed = True
        for index in range(1, 16):
            checks.append((f"ansi{index}", values[f"NIRU_TERM_ANSI_{index}"], 4.5))
        for name, colour, minimum in checks:
            ratio = contrast(bg, colour)
            if ratio < minimum:
                print(f"{path.name}: {name} {colour} contrast {ratio:.2f} < {minimum}")
                failed = True
        print(f"{path.name}: background {bg}, foreground {contrast(bg, fg):.2f}:1")
    if failed:
        return 1
    print("PASS: all built-in terminal palettes are readable")
    return 0


if __name__ == "__main__":
    sys.exit(main())
