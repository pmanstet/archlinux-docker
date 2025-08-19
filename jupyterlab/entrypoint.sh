#!/usr/bin/env bash
set -x # print expanded commands
set -o pipefail # prevent errors masked by pipes
set -e # exit on error

# assumptions/assertions: 
# - this script is run as root
test $(id -u) -eq 0
# - default target user is  jovyan:.*:1000:100:.*:/home/jovyan:.*
# - overruled by envvars -> NB_USER:.*:NB_UID:NB_GID:.*:NB_HOME:.*
export NB_USER="${NB_USER:-jovyan}"
export NB_UID="${NB_UID:-1000}"
export NB_GID="${NB_GID:-100}"
export NB_HOME="${NB_HOME:-"/home/${NB_USER}"}"
# - home of target user is mounted and owned by target user (at least by the prim. group)
test -d "${NB_HOME}"
test $(stat -c "%g" "${NB_HOME}") -eq ${NB_GID}
# - target uid is above 1000 (ie not a system user)
test ${NB_UID} -ge 1000

# add target user to system
groupadd -g "${NB_GID}" "${NB_USER}" || true
useradd  --no-create-home --no-log-init --no-user-group --home-dir "${NB_HOME}" --gid "${NB_GID}" --uid "${NB_UID}" "${NB_USER}"

# drop privileges and start jupyterlab/jupyterhub 
if test ${JUPYTERHUB_SERVICE_URL}; then
    exec sudo --preserve-env --set-home --user "${NB_USER}" bash -c 'cp -Rn /etc/skel/. ~/. && source /opt/venv/bin/activate && jupyterhub-singleuser --ip=0.0.0.0 --no-browser'
else
    exec sudo --preserve-env --set-home --user "${NB_USER}" bash -c 'cp -Rn /etc/skel/. ~/. && source /opt/venv/bin/activate && jupyter lab --ip=0.0.0.0 --no-browser'
fi
