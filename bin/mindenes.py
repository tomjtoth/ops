#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import run as sp_run, DEVNULL, check_output
import sys
import os
import subprocess
from pathlib import Path
# import paramiko

PATH_HOME = os.environ["HOME"]


def cmd2str(cmd: str) -> str:
    return check_output(cmd.split(), stderr=DEVNULL).decode('utf-8')


def run(cmd: str):
    sp_run(cmd.split())


class Host:
    def __init__(self, addr: str,
                 user_ssh='test',
                 port_ssh=55522,
                 port_iperf=55524,
                 port_adb=55525,
                 path_ssh_key=PATH_HOME + '/.ssh/id_ed25519.pub',
                 path_data='/home/ttj',
                 path_torrents='/home/downloads/torrents'):

        self.addr = addr

        self.port_ssh = port_ssh
        self.port_iperf = port_iperf
        self.port_adb = port_adb

        self.user_ssh = user_ssh

        self.path_ssh_key = path_ssh_key
        self.path_data = path_data
        self.path_torrents = path_torrents

    def process(self, args):
        if args.ssh:
            run(f"ssh -p {self.port_ssh} {self.user_ssh}@{self.addr}")

        if args.sshfs or args.umount:
            path = f"{PATH_HOME}/.remotes/{args.host}"
            if os.path.exists(path):
                run(f"fusermount -u {path}")
            else:
                Path(path).mkdir(parents=True)

            if args.sshfs:
                run(f"sshfs -p {self.port_ssh} {self.user_ssh}@{self.addr}:/ {path}")

        if args.ssh_socks5:
            run(
                f"ssh -N -q -R 0:localhost:55523 -p {self.port_ssh} -A -D 1080 {self.user_ssh}@{self.addr}"
            )

        if args.backup or args.backup_linux:
            subprocess.run("rsync --progress --stats --inplace --exclude=.share_info --exclude=.debris --exclude=documents --exclude=target/debug --exclude=target/release --delete-after -Ha -e".split()
                           + [f"ssh -p {self.port_ssh}"] + f"/home/ttj{'/' if args.backup else '/soft-hard-ware/linux/'} {self.user_ssh}@{self.addr}:{self.path_data}{'' if args.backup else '/soft-hard-ware/linux'}".split())

        if args.ping:
            run(f"ping -c 3 {self.addr}")

        if args.trace:
            run(f"traceroute {self.addr}")

        if args.iperf:
            run(f"ssh -t {self.addr} -p {self.port_ssh} \"iperf3 -s -1 -p {self.port_iperf}\"")
            run(f"iperf3 -c {self.addr} -p {self.port_iperf}")

# Host declarations here


DEFAULT_HOST = 'rk3328'
hosts = {
    # Host(cmd2str('ip route get 1.1.1.1').split()[2]),
    'router': Host('home'),
    # 'rk3328': Host('rk3328.tomjtoth.freeddns.org',
    'rk3328': Host('attilacsabatoth.ddns.net',
                   port_ssh=22666,
                   user_ssh='tamas',
                   path_data='/mnt/data/tomi'
                   ),
    'oracle-dev': Host('oracle.ttj.hu',
                       port_ssh=22,
                       user_ssh='ubuntu',
                       ),
    'gcp': Host('gcp.tomjtoth.h4ck.me',
                port_ssh=22,
                user_ssh='tomjtoth',
                ),
    'km8p': Host('km8p.tomjtoth.h4ck.me'),  # km8p.tomjtoth.freeddns.org
    'a544': Host('a544.home'),
    'L450': Host('10.0.1.1'),
    'iv2201': Host('192.168.1.191',
                   path_data='/storage/emulated/0/tomjtoth'
                   ),
    'opzp': Host('opzp.home'),
    'ebook820g4': Host('ebook820g4.home')
}

ap = ArgumentParser()
ap.add_argument('host', nargs='?', metavar='HOST',
                help='the host to connect to')

ap.add_argument('-s', '--ssh', action='store_true',
                help='connects to HOST via SSH')
ap.add_argument('-sf', '--sshfs', action='store_true',
                help='mounts HOST at ~/.remotes/HOST')
ap.add_argument('-u', '--umount', action='store_true',
                help='unmounts ~/.remotes/HOST')
ap.add_argument('-ss', '--ssh-socks5', action='store_true',
                help='tunnels a SOCKS5 socket via SSH to HOST')

ap.add_argument('-b', '--backup', action='store_true',
                help=f'mirrors {hosts["router"].path_data} to HOST')
ap.add_argument('-bl', '--backup-linux', action='store_true',
                help=f'mirrors {hosts["router"].path_data}/soft-hard-ware/linux to HOST')

ap.add_argument('-sn', '--nmap', action='store_true',
                help='look for online hosts on LAN')
ap.add_argument('--ports', action='store_true', help='scans open ports')

ap.add_argument('--ping', action='store_true', help='pings 1.1.1.1 or HOST')
ap.add_argument('-t', '--trace', action='store_true',
                help='traces route to 1.1.1.1 or HOST')
ap.add_argument('--iperf', action='store_true',
                help='measures network performance between HOST and you')

ap.add_argument('-dd', '--dconf-dump', action='store_true',
                help='dumps dconf settings to the common file')
ap.add_argument('-dl', '--dconf-load', action='store_true',
                help='loads dconf settings from the common file')


# change False <-> True to toggle testing
args = ap.parse_args("-s 0".split() if False else None)

if args.host:

    if args.host in hosts:
        host = hosts[args.host]
    elif args.host == '0':
        host = hosts[DEFAULT_HOST]
    else:
        print(f"unrecognized host: {args.host}")
        sys.exit(1)

    host.process(args)

else:

    if args.nmap:
        run(f'nmap -sn {hosts["router"].addr}/24')

    if args.dconf_dump:
        with open(PATH_HOME+"/soft-hard-ware/linux/home/.config/dconf/dump", "w") as fp:
            subprocess.run("dconf dump /".split(), stdout=fp)
            print("dconf settings dumped")

    elif args.dconf_load:
        with open(PATH_HOME+"/soft-hard-ware/linux/home/.config/dconf/dump", "r") as fp:
            subprocess.run("dconf load /".split(), stdin=fp)
            print("dconf settings loaded")
