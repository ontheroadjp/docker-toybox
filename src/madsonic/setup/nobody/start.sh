#!/bin/sh

#create folders on config
mkdir -p /config/media/incoming
mkdir -p /config/media/podcast
mkdir -p /config/playlists/import
mkdir -p /config/playlists/export
mkdir -p /config/playlists/backup
mkdir -p /config/transcode

#copy transcode to config directory - transcode directory is subdir of path set from --home flag, do not alter
cp /opt/madsonic/transcode/linux/* /config/transcode/

# enable/disable ssl based on env variable set from docker container run command
 if [[ $SSL == "yes" ]]; then
	echo "Enabling SSL for Madsonic"
	port="--https-port=4050"
elif [[ $SSL == "no" ]]; then
	echo "Disabling SSL for Madsonic"
	port="--port=4040"
 fi

 # if context path not defined then set to empty string (default root context)
 if [[ -z "${CONTEXT_PATH}" ]]; then
	CONTEXT_PATH="/"
 fi

# run madsonic with flags to set config
/opt/madsonic/madsonic.sh --home=/config --host=0.0.0.0 ${port} --context-path=${CONTEXT_PATH} --default-music-folder=/media --default-podcast-folder=/config/media/podcast --default-playlist-import-folder=/config/playlists/import --default-playlist-export-folder=/config/playlists/export --default-playlist-backup-folder=/config/playlists/backup