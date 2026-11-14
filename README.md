# system-info-cli

A small Bash script that prints a summary of a Linux machine: OS, kernel, uptime, CPU, memory, disk, battery and local IP address.

```console
$ ./sysinfo.sh

System
  OS         EndeavourOS
  Kernel     7.2.14-arch1-1
  Hostname   victus
  Uptime     1d 6h 51m

CPU
  Model      12th Gen Intel(R) Core(TM) i5-12450H
  Cores      12
  Usage      4%
  Load       0.52 0.61 0.70

Memory
  Total      23.1G
  Used       9.8G (42%)

Disk (/)
  Total      467G
  Used       420G (95%)

Battery (BAT0)
  Charge     87%, Discharging

Network
  Local IP   192.168.1.24
```

## Usage

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

| Option | What it does |
|:--|:--|
| `-n`, `--net` | Also look up the public IP address and the local weather. |
| `--no-color` | Plain output. This is also the default when the output is piped, or when `NO_COLOR` is set. |
| `-h`, `--help` | Show the help text. |

## Notes

- Everything is read locally, mostly from `/proc` and `/sys`, so it works the same across distributions and needs nothing beyond Bash and the usual core utilities.
- Nothing is sent over the network unless you pass `--net`. That option contacts [ifconfig.me](https://ifconfig.me) and [wttr.in](https://wttr.in), with a four-second limit on each, and needs `curl`.
- A value the machine doesn't expose is shown as `unavailable`.

## Tests

Run `python -m unittest discover -s tests -v` on Linux with Python 3.8 or newer.
The tests use only the standard library and stub network requests; they do not
contact external services.
