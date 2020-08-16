#!/usr/bin/env python3

import os
import subprocess
from pwd import getpwuid

import click

from internal import OsUser, IP


def get_tz() -> str:
    """Return OS timezone in `Europe/London` format"""
    s = subprocess.run(["timedatectl", "--value", "show", "-p", "Timezone"], capture_output=True, text=True, check=True)
    return s.stdout.strip()


def get_primary_iface() -> str:
    """Return primary network interface in use, empty string if not found"""
    primary_iface = ''
    s = subprocess.run(["netstat", "--route", "--numeric"], capture_output=True, text=True, check=True)
    for line in s.stdout.split('\n'):
        tmp = line.split()
        if tmp[0] == '0.0.0.0':
            primary_iface = tmp[-1].strip()
            break
    return primary_iface


def iface_ip(iface: str) -> IP:
    """Return a namedtuple with the interface's IP addresses"""
    s = subprocess.run(["ip", "-o", "address", "show", "scope", "global", iface], capture_output=True,
                       text=True, check=True)
    ip_temp = s.stdout.split('\n')
    # First line ipv4, second ipv6 (only one line if no v6)
    # index 2: inet or inet6
    # index 3: actual IP with mask, /24 or /64
    ip_4 = ip_temp[0].split()[3].split('/', 1)[0]
    ip_6 = ''
    if len(ip_temp) > 1 and ip_temp[1]:
        ip_6 = ip_temp[1].split()[3].split('/', 1)[0]
    return IP(ip_4, ip_6)


@click.group()
@click.option('--user', '-u', default=getpwuid(os.getuid()).pw_name, show_default=True,
              help='Username to run service as')
@click.option('--iface', default=get_primary_iface(), show_default=True,
              help='Network interface to use when determining IP addresses')
@click.option('--tz', default=get_tz(), show_default=True, help='Timezone to use')
def cli(user: str, iface: str, tz: str):
    user = OsUser.from_username(user)
    ip = iface_ip(iface)
    status_dict = {
        "User": f'{user.name} [{user.uid}]',
        "Group": f'{user.group} [{user.gid}]',
        "TZ": tz,
        "IPV4": ip.four,
        "IPV6": ip.six,
    }
    padding = len(max(status_dict.keys(), key=len)) + 2
    lines = []
    for k, v in status_dict.items():
        if v:
            lines.append(f'{k:{padding}s}: {v}')
    click.echo('\n'.join(lines))


@cli.command(name='run')
def cli_run():
    click.echo("RUN")


if __name__ == '__main__':
    cli()
