"""Run with python -m unittest discover -s tests -v (no dependencies)."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "sysinfo.sh"


class SysinfoTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.env = dict(os.environ, PATH=f"{self.directory}:{os.environ['PATH']}")
        self.env["TEST_DIRECTORY"] = str(self.directory)
        self.stub("sleep", "exit 0\n")
        self.stub("curl", 'printf "%s\\n" "$*" >> "$TEST_DIRECTORY/network"\nprintf "test-value"\n')

    def stub(self, name, body):
        path = self.directory / name
        path.write_text("#!/usr/bin/env bash\n" + body)
        path.chmod(0o755)

    def run_script(self, *args):
        return subprocess.run(
            ["bash", str(SCRIPT), *args], env=self.env,
            text=True, capture_output=True, check=True, timeout=10,
        ).stdout

    def test_guest_time_is_not_counted_twice(self):
        # 50 busy ticks and 50 idle ticks must remain 50%, even when some
        # busy time belongs to normal or niced virtual-machine guests.
        samples = [
            ("100 0 0 100 0 0 0 0 80 0", "150 0 0 150 0 0 0 0 120 0"),
            ("0 100 0 100 0 0 0 0 0 80", "0 150 0 150 0 0 0 0 0 120"),
        ]
        for before, after in samples:
            with self.subTest(before=before):
                self.env.update(CPU_BEFORE=before, CPU_AFTER=after)
                (self.directory / "sampled").unlink(missing_ok=True)
                self.stub("head", '''if [ -e "$TEST_DIRECTORY/sampled" ]; then
    printf 'cpu %s\\n' "$CPU_AFTER"
else
    touch "$TEST_DIRECTORY/sampled"
    printf 'cpu %s\\n' "$CPU_BEFORE"
fi
''')
                self.assertRegex(self.run_script("--no-color"), r"Usage\s+50%")

    def test_unchanged_cpu_counters_are_unavailable(self):
        self.stub("head", "printf 'cpu 100 0 0 100 0 0 0 0 0 0\\n'\n")
        self.assertRegex(self.run_script(), r"Usage\s+unavailable")

    def test_default_run_is_offline_and_plain_when_piped(self):
        output = self.run_script()
        self.assertFalse((self.directory / "network").exists())
        self.assertNotIn("\x1b[", output)
        self.assertIn("System", output)

    def test_network_requests_are_opt_in_and_bounded(self):
        output = self.run_script("--net")
        requests = (self.directory / "network").read_text().splitlines()
        self.assertEqual(len(requests), 2)
        for request in requests:
            self.assertIn("--max-time 4", request)
        self.assertIn("https://ifconfig.me/ip", requests[0])
        self.assertIn("https://wttr.in/", requests[1])
        self.assertRegex(output, r"Public IP\s+test-value")


if __name__ == "__main__":
    unittest.main()
