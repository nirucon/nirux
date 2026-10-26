#!/usr/bin/env python3
"""Native protocol regression: no root or real network mutation required."""
import pathlib
import runpy
import unittest
from unittest.mock import patch

helper = runpy.run_path(str(pathlib.Path(__file__).resolve().parents[1] / "polkit/nirux-wifi"))


class ProtocolTests(unittest.TestCase):
    def test_mutations_and_secrets_have_a_fixed_stdin_protocol(self):
        for command in (["set_network", "2", "ssid", "räknät"],
                        ["set_network", "2", "psk", "test-only-secret"],
                        ["select_network", "2"], ["save_config"]):
            helper["validate_command"](command)

    def test_program_execution_and_global_control_are_rejected(self):
        for command in (["-a", "/tmp/action"], ["terminate"], ["raw", "anything"],
                        ["interface_add", "wlan9"], ["set_network", "2", "config_file", "/tmp/x"],
                        ["set_network", "2;id", "psk", "bad"]):
            with self.assertRaises(ValueError):
                helper["validate_command"](command)

    def test_arguments_cannot_select_an_action_script(self):
        with self.assertRaises(ValueError):
            helper["request"](["-a", "/tmp/action"])
        with patch("os.path.isdir", return_value=True):
            with self.assertRaises(ValueError):
                helper["request"](["-i", "wlan0", "-a", "/tmp/action"])

    def test_radio_protocol_cannot_change_networking(self):
        with self.assertRaises(ValueError):
            helper["request"](["radio", "networking-off"])


if __name__ == "__main__":
    unittest.main()
