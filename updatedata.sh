#!/bin/bash

# IMPORTANT: Source RVM as a function into local environment.
#            Otherwise switching gemsets won't work.
[ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

# Enable shell debugging.
set -x

echo "borrando proyectos"
mongo inteligente rmbills.js
echo "bajando proyectos de nuevo"
ruby sil.rb
cd ~/billit-api-cl/
echo "reindexando"
rvm use 1.8.7-p358@billit-api-cl
ruby commands.rb reindex
