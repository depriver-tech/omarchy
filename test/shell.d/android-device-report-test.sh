#!/bin/bash

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

python3 - "$ROOT" <<'PY'
import importlib.util
import contextlib
import io
import pathlib
import subprocess
import sys
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
  "report", pathlib.Path(sys.argv[1]) / "scripts/android-device-report.py")
report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(report)
sys.argv = sys.argv[:1]


class DeviceReportTest(unittest.TestCase):
  def test_selection_allowlist_and_missing_properties(self):
    calls = []
    def run(argv, **kwargs):
      calls.append(argv)
      self.assertTrue(kwargs["check"])
      self.assertEqual(kwargs["timeout"], 15)
      value = "test-kernel\n" if argv[-2:] == ["uname", "-r"] else "\n"
      return subprocess.CompletedProcess(argv, 0, stdout=value)
    result = report.collect("selected-device", run=run)
    self.assertEqual(result["kernel_release"], "test-kernel")
    self.assertTrue(all(value is None for value in result["properties"].values()))
    self.assertNotIn("selected-device", str(result))
    allowed = [["shell", "getprop", key] for key in report.PROPERTIES.values()]
    allowed.append(["shell", "uname", "-r"])
    self.assertEqual(calls, [["adb", "-s", "selected-device"] + args for args in allowed])

  def test_connection_failure_does_not_produce_report(self):
    for error in [FileNotFoundError(), subprocess.TimeoutExpired("adb", 15),
                  subprocess.CalledProcessError(1, "adb")]:
      with self.subTest(error=error):
        def run(*args, **kwargs):
          raise error
        with self.assertRaises(type(error)):
          report.collect(run=run)

  def test_cli_failure_is_private_and_emits_no_json(self):
    out, err = io.StringIO(), io.StringIO()
    failure = subprocess.CalledProcessError(1, "adb", stderr="private-device-id")
    with patch.object(report, "collect", side_effect=failure), \
         contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
      self.assertEqual(report.main(), 1)
    self.assertEqual(out.getvalue(), "")
    self.assertNotIn("private-device-id", err.getvalue())
    self.assertIn("Cannot read device", err.getvalue())


unittest.main()
PY
