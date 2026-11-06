#!/bin/sh
# Baja los plugins en los commits de plugins.lock a plugins-src/.
# Corre fuera de Docker para usar tu SSH: SciELO-JATS-Converter es privado.
set -eu
cd "$(dirname "$0")/.."

rm -rf plugins-src
grep -v '^#' docker/plugins.lock | while read -r path repo commit; do
    echo "==> $path ($repo @ $commit)"
    git clone --quiet "git@github.com:$repo.git" "plugins-src/$path"
    git -C "plugins-src/$path" checkout --quiet "$commit"
    git -C "plugins-src/$path" submodule update --quiet --init --recursive
    find "plugins-src/$path" -name .git -prune -exec rm -rf {} +
done
