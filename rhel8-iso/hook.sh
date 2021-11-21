#!/usr/bin/env bash
set -e

mkdir -p infraunlimited
curl https://github.com/infraunlimitedowner.keys -o infraunlimited/ssh.pub
