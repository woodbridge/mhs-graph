#! /bin/bash

echo "backing up database.db"
scp justinwoodbridge.com:apps/mhsgraph/database.db backups/

echo "backing up mhs.dot"
scp justinwoodbridge.com:apps/mhsgraph/mhs.dot backups/