#!/bin/sh

cp docker-stacks.service /etc/systemd/system
systemctl daemon-reload
systemctl enable docker-stacks
