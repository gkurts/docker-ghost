#!/bin/bash
set -e

# allow the container to be started with `--user`
if [[ "$*" == node*current/index.js* ]] && [ "$(id -u)" = '0' ]; then
	chown -R node "$GHOST_CONTENT"
	exec gosu node "$BASH_SOURCE" "$@"
fi

if [[ "$*" == node*current/index.js* ]]; then
	baseDir="$GHOST_INSTALL/content.orig"
	for src in "$baseDir"/*/ "$baseDir"/themes/*; do
		src="${src%/}"
		target="$GHOST_CONTENT/${src#$baseDir/}"
		mkdir -p "$(dirname "$target")"
		if [ ! -e "$target" ]; then
			tar -cC "$(dirname "$src")" "$(basename "$src")" | tar -xC "$(dirname "$target")"
		fi
	done
	
	# remove the symlink to the casper theme and put the actual files there.
	# this will require manually updating the latest version but if we're developing
	# new themes then we really shouldn't care. I think.
	rm $GHOST_CONTENT/themes/casper
	echo "rm'd the casper symlink."

	cp -r $GHOST_INSTALL/current/content/themes/casper $GHOST_CONTENT/themes/casper
	echo "cp'd the casper files to the theme folder."

	knex-migrator-migrate --init --mgpath "$GHOST_INSTALL/current"
fi

exec "$@"
