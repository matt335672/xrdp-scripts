#!/bin/sh

cd $(dirname $0) || exit $?

set -e

./myconfig.sh 
gmake clean
rm -rf cov-int
cov-build --dir cov-int gmake
tar czvf /tmp/xrdp.tgz cov-int
scp /tmp/xrdp.tgz andelain.lan:/tmp/
echo "Coverity rebuild completed successfully"
