#!/bin/sh
# Script para preparar e limpar ambiente chroot completo

CHROOT_DIR="$1"

if [ -z "$CHROOT_DIR" ]; then
    echo "[FAIL] Use: $0 <diretório_chroot>"
    exit 1
fi

log() {
    prefix="$1"
    shift
    case "$prefix" in
        INFO)  echo "\033[1;34m[$prefix] $*\033[0m" ;;
        OK)    echo "\033[1;32m[$prefix] $*\033[0m" ;;
        WARN)  echo "\033[1;33m[$prefix] $*\033[0m" ;;
        FAIL)  echo "\033[1;31m[$prefix] $*\033[0m" ;;
        *)     echo "[$prefix] $*" ;;
    esac
}

check_mount() {
    mountpoint="$1"
    grep -qs "$mountpoint" /proc/mounts
}

mount_chroot() {
    log INFO "Preparando chroot em $CHROOT_DIR"
    [ -d "$CHROOT_DIR" ] || { log FAIL "Diretório $CHROOT_DIR não existe"; exit 1; }

    # Bind /dev
    if ! check_mount "$CHROOT_DIR/dev"; then
        log INFO "Montando /dev"
        mount --bind /dev "$CHROOT_DIR/dev"
    else
        log WARN "/dev já montado"
    fi

    # Bind /dev/pts
    if ! check_mount "$CHROOT_DIR/dev/pts"; then
        log INFO "Montando /dev/pts"
        mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
    else
        log WARN "/dev/pts já montado"
    fi

    # Proc
    if ! check_mount "$CHROOT_DIR/proc"; then
        log INFO "Montando /proc"
        mount -t proc proc "$CHROOT_DIR/proc"
    else
        log WARN "/proc já montado"
    fi

    # Sys
    if ! check_mount "$CHROOT_DIR/sys"; then
        log INFO "Montando /sys"
        mount -t sysfs sys "$CHROOT_DIR/sys"
    else
        log WARN "/sys já montado"
    fi

    # Optional: /run
    if ! check_mount "$CHROOT_DIR/run"; then
        log INFO "Montando /run"
        mount --bind /run "$CHROOT_DIR/run"
    else
        log WARN "/run já montado"
    fi

    log OK "Ambiente chroot preparado"
}

enter_chroot() {
    log INFO "Entrando no chroot..."
    chroot "$CHROOT_DIR" /bin/bash
}

umount_chroot() {
    log INFO "Desmontando pseudo-filesystems"
    for mp in run sys proc dev/pts dev; do
        target="$CHROOT_DIR/$mp"
        if check_mount "$target"; then
            log INFO "Desmontando $target"
            umount -lf "$target"
        else
            log WARN "$target não está montado"
        fi
    done
    log OK "Chroot limpo"
}

# ===== EXECUÇÃO =====
mount_chroot
enter_chroot
umount_chroot
