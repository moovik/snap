#!/bin/bash
wget --trust-server-names -P /root/solana/snapshots/ http://api.mainnet-beta.solana.com/snapshot.tar.bz2
wget --trust-server-names -P /root/solana/snapshots/ http://api.mainnet-beta.solana.com/incremental-snapshot.tar.bz2
systemctl daemon-reload && systemctl restart solana.service
solana-validator --ledger /root/solana/ledger monitor
