#!/bin/sh
# Bootstrap LFS (Capítulos 1-6) usando pkg.sh
# Uso: sudo ./lfs-bootstrap.sh <diretório_lfs_root>

LFS_ROOT="$1"
[ -z "$LFS_ROOT" ] && { echo "[FAIL] Use: $0 <diretório_lfs_root>"; exit 1; }

# Variáveis de ambiente
export INSTALL_PREFIX="$LFS_ROOT"
export WORKDIR="$HOME/lfs_build"
export BUILDDIR="$HOME/repo/build"
export PATCHDIR="$HOME/repo/patch"
export LOGDIR="$HOME/.local/pkglogs"
export MOTOR_SCRIPT="$HOME/bin/prepare.sh"
export INSTALL_SCRIPT="$HOME/bin/install.sh"
export REMOVE_SCRIPT="$HOME/bin/remove.sh"

mkdir -p "$LFS_ROOT"
mkdir -p "$WORKDIR"
mkdir -p "$LOGDIR"

log() {
    prefix="$1"; shift
    case "$prefix" in
        INFO)  echo "\033[1;34m[$prefix] $*\033[0m" ;;
        OK)    echo "\033[1;32m[$prefix] $*\033[0m" ;;
        WARN)  echo "\033[1;33m[$prefix] $*\033[0m" ;;
        FAIL)  echo "\033[1;31m[$prefix] $*\033[0m" ;;
        *)     echo "[$prefix] $*" ;;
    esac
}

# Lista de pacotes do Capítulo 5-6 LFS (exemplo simplificado)
PACKAGES="
binutils
gcc
gmp
mpfr
mpc
bash
coreutils
file
findutils
gawk
grep
sed
tar
texinfo
xz
patch
gzip
bzip2
"

# Montar pseudo-filesystems e entrar em chroot
log INFO "Preparando chroot e pseudo-filesystems"
sudo "$HOME/bin/chroot-pkg.sh" "$LFS_ROOT" $PACKAGES

log OK "Bootstrap LFS (cap.1-6) concluído!"
echo "Todos os pacotes instalados em $LFS_ROOT"
echo "Logs em $LOGDIR"
echo "Entre no chroot usando: sudo chroot $LFS_ROOT /bin/bash"
