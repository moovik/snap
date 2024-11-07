#!/bin/bash
wget --trust-server-names -P /mnt/disk1/snapshots/ http://api.mainnet-beta.solana.com/snapshot.tar.bz2
wget --trust-server-names -P /mnt/disk1/snapshots/ http://api.mainnet-beta.solana.com/incremental-snapshot.tar.bz2
systemctl daemon-reload && systemctl restart solana.service
 agave-validator --ledger /mnt/disk1/ledger/ monitor
