#!/bin/bash

case "$1" in
  "1")
    wget --trust-server-names -P /mnt/disk1/snapshots http://api.mainnet-beta.solana.com/snapshot.tar.bz2
    ;;
  "2")
    wget --trust-server-names -P /mnt/disk1/snapshots http://api.mainnet-beta.solana.com/incremental-snapshot.tar.bz2
    ;;
  *)
    wget --trust-server-names -P /mnt/disk1/snapshots http://api.mainnet-beta.solana.com/snapshot.tar.bz2
    wget --trust-server-names -P /mnt/disk1/snapshots http://api.mainnet-beta.solana.com/incremental-snapshot.tar.bz2
    ;;
esac
