#!/bin/sh
# Script para chroot + instalação automática de pacotes via pkg.sh
# Uso: sudo ./chroot-pkg.sh <diretório_chroot> [pacotes...]

CHROOT_DIR="$1"
shift
PKGS="$@"

[ -z "$CHROOT_DIR" ] && { echo "[FAIL] Use: $0 <diretório_chroot> [pacotes]"; exit 1; }

# ===== FUNÇÕES =====

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

check_mount() {
    grep -qs "$1" /proc/mounts
}

mount_chroot() {
    log INFO "Preparando chroot em $CHROOT_DIR"
    [ -d "$CHROOT_DIR" ] || { log FAIL "Diretório $CHROOT_DIR não existe"; exit 1; }

    for mp in dev dev/pts proc sys run; do
        target="$CHROOT_DIR/$mp"
        [ -d "$target" ] || mkdir -p "$target"
        if ! check_mount "$target"; then
            case "$mp" in
                proc) mount -t proc proc "$target" ;;
                sys) mount -t sysfs sys "$target" ;;
                *) mount --bind /$mp "$target" ;;
            esac
            log INFO "Montado $target"
        else
            log WARN "$target já montado"
        fi
    done
}

umount_chroot() {
    log INFO "Desmontando pseudo-filesystems"
    for mp in run sys proc dev/pts dev; do
        target="$CHROOT_DIR/$mp"
        if check_mount "$target"; then
            log INFO "Desmontando $target"
            umount -lf "$target"
        fi
    done
    log OK "Chroot limpo"
}

install_packages_chroot() {
    if [ -z "$PKGS" ]; then
        log WARN "Nenhum pacote especificado, pulando instalação"
        return
    fi

    for pkg in $PKGS; do
        log INFO "Instalando pacote $pkg no chroot"
        # Copia pkg.sh e scripts para dentro do chroot temporariamente
        cp -a "$HOME/bin/pkg.sh" "$CHROOT_DIR/usr/bin/pkg.sh"
        cp -a "$HOME/bin/prepare.sh" "$CHROOT_DIR/usr/bin/prepare.sh"
        cp -a "$HOME/bin/install.sh" "$CHROOT_DIR/usr/bin/install.sh"
        cp -a "$HOME/repo/build/$pkg.sh" "$CHROOT_DIR/repo/build/$pkg.sh"

        chroot "$CHROOT_DIR" /bin/bash -c "export INSTALL_PREFIX=/; export WORKDIR=/build; export LOGDIR=/pkglogs; mkdir -p /build /pkglogs; /usr/bin/pkg.sh install $pkg"
    done
}

# ===== EXECUÇÃO =====

mount_chroot
install_packages_chroot
log INFO "Entrando no chroot para uso interativo..."
chroot "$CHROOT_DIR" /bin/bash
umount_chroot
