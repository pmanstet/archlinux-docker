# build archlinux:base-devel

- this needs an archlinux host

```shell
# sudo pacman -Sy make devtools git podman fakechroot fakeroot
make clean
make image-base-devel
podman image ls
podman run -it --rm archlinux/archlinux:base-devel
```

# build archlinux:jupyterlab
```shell 
podman build -f jupyterlab/Dockerfile.jupyterlab -t archlinux/archlinux:jupyterlab jupyterlab
podman image ls
podman image prune
podman run -it --rm archlinux/archlinux:jupyterlab
podman run -it --rm -p 8888:8888 archlinux/archlinux:jupyterlab
```
