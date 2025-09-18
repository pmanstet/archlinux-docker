# build archlinux:base-devel

**Note**: requires an archlinux host

```shell
# sudo pacman -Sy make devtools git podman fakechroot fakeroot
make clean
make image-base
podman image ls
podman run -it --rm localhost/archlinux/archlinux:base
```

# build/test archlinux:jupyterlab

```shell
# build image
export DATE_ISO=2025-09-10

# optional: build code-server stage
podman build --target code-server \
    --build-arg ARG_DATE_ISO="${DATE_ISO}" \
    -f jupyterlab/Dockerfile.jupyterlab \
    -t localhost/archlinux/archlinux:code-server \
    jupyterlab
podman run --rm -it -p 8080:8080 localhost/archlinux/archlinux:code-server
# open ->  http://0.0.0.0:8080 to test

# build full image
podman build \
    --build-arg ARG_DATE_ISO="${DATE_ISO}" \
    -f jupyterlab/Dockerfile.jupyterlab \
    -t localhost/archlinux/archlinux:jupyterlab \
    jupyterlab

# extract package info form container filesystem
podman create --name temp localhost/archlinux/archlinux:jupyterlab
podman cp temp:"/${DATE_ISO}/." "./jupyterlab/${DATE_ISO}/"
podman rm temp
# clean up local images
podman image prune --force
for i in `podman ps --all --storage | sed '1d' | awk '{print$1}'`; do podman rm $i --force ; done
# inspect image size contributed by each layer
podman history --no-trunc localhost/archlinux/archlinux:jupyterlab

# create volume to be used as home and populate with /etc/skel of host
podman volume rm demohome || true
podman volume create demohome --opt o=uid=$(id -u),gid=$(id -g)
DEMOHOME=$(podman volume inspect demohome --format={{.Mountpoint}})
podman unshare cp -r /etc/skel/. "${DEMOHOME}/"
podman unshare chown -R $(id -u):$(id -g) "${DEMOHOME}"
podman unshare ls -la "${DEMOHOME}"

# start local jupyter lab
podman run --rm -it \
    -p 8888:8888 \
    -e NB_UID=$(id -u) \
    -e NB_GID=$(id -g) \
    -e NB_USER=$(id -nu) \
    -v demohome:/home/$(id -nu) \
    -w /home/$(id -nu) \
    localhost/archlinux/archlinux:jupyterlab

# -> open link prodived in console in the browser to test e.g.
# http://127.0.0.1:8888/lab?token=XXXXXXXXXXXXX
# to wipe persistent home with default settings: cp -rf /etc/skel/. ~/

# start "fake" jupyter hub -> expected to fail as no hub is running
podman run --rm -it -e JUPYTERHUB_SERVICE_URL="fake" \
    -e NB_UID=$(id -u) \
    -e NB_GID=$(id -g) \
    -e NB_USER=$(id -nu) \
    -v demohome:/home/$(id -nu) \
    -w /home/$(id -nu) \
    localhost/archlinux/archlinux:jupyterlab

# cleanup
podman volume rm demohome
```

# publish archlinux/archlinux:jupyterlab

```shell
# OWN_REGISTRY=...
# OWN_PROJECT=...
# OWN_USERNAME=...
podman login -u "${OWN_USERNAME}" "${OWN_REGISTRY}" --password-stdin <<< $(pass "${OWN_REGISTRY}/${OWN_USERNAME}")

podman tag localhost/archlinux/archlinux:jupyterlab "${OWN_REGISTRY}/${OWN_PROJECT}/archlinux:jupyterlab"
podman image ls | grep "${OWN_REGISTRY}"
podman push "${OWN_REGISTRY}/${OWN_PROJECT}/archlinux:jupyterlab"

podman logout "${OWN_REGISTRY}" || true
```
