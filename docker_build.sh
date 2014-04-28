#!/bin/bash
set -euo pipefail -x
docker build -t storm-deb-packaging .

# Bump this before the next build.
packaging_version=3

# TODO: is there a better way to get a file out of a docker container?
# "docker cp" gave me the "Tarball too short" error.
docker run storm-deb-packaging bash -c "
  cd ~/build/storm-deb-packaging >&2 && 
  rm -f *.deb >&2 &&
  USER=root ./build_storm.sh --packaging_version ${packaging_version} >&2 &&
  chmod a+r ~/build/storm-deb-packaging/*.deb >&2 &&
  ls -l *.deb >&2 && 
  cat \$(ls -t *.deb | head -1)
" >tmp.deb

pkg_version=$(dpkg --info tmp.deb | grep Version | awk '{print $2}')
mv -f tmp.deb "storm_${pkg_version}_all.deb"

