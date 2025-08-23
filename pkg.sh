#!/bin/sh

. "$HOME/.profile"

# ===== Funções =====

help() {
    cat <<EOF
Uso: pkg.sh <comando> [pacote]

Comandos:
  install <pacote>     - Instala o pacote (resolve dependências recursivas)
  remove <pacote>      - Remove o pacote usando log de instalação
  search <termo>       - Busca pacotes disponíveis no BUILDDIR
  info <pacote>        - Mostra informações do pacote (receita)
  rebuild              - Recompila todo o sistema (todas as receitas em BUILDDIR)
  help                 - Mostra este help
EOF
}

# ===== Comandos =====

install_pkg() {
    recipe="$BUILDDIR/$1.sh"
    if [ ! -f "$recipe" ]; then
        echo "Pacote não encontrado: $1" >&2
        return 1
    fi
    "$INSTALL_SCRIPT" "$recipe"
}

remove_pkg() {
    recipe="$BUILDDIR/$1.sh"
    if [ ! -f "$recipe" ]; then
        echo "Pacote não encontrado: $1" >&2
        return 1
    fi
    "$REMOVE_SCRIPT" "$recipe"
}

search_pkg() {
    term="$1"
    find "$BUILDDIR" -type f -name "*.sh" | xargs -n1 basename | grep "$term"
}

info_pkg() {
    recipe="$BUILDDIR/$1.sh"
    if [ ! -f "$recipe" ]; then
        echo "Pacote não encontrado: $1" >&2
        return 1
    fi
    echo "Informações do pacote $1:"
    grep -E "^(NAME|VERSION|SOURCE|DEPS|PATCH|BUILD)" "$recipe"
    logfile="$LOGDIR/$1-*.log"
    echo "Arquivos instalados (log): $logfile"
}

rebuild_system() {
    for recipe in "$BUILDDIR"/*.sh; do
        pkgname=$(basename "$recipe" .sh)
        echo "==> Recompilando $pkgname"
        install_pkg "$pkgname"
    done
}

# ===== Execução =====

cmd="$1"
shift || true

case "$cmd" in
    install) install_pkg "$1" ;;
    remove) remove_pkg "$1" ;;
    search) search_pkg "$1" ;;
    info)   info_pkg "$1" ;;
    rebuild) rebuild_system ;;
    help|"" ) help ;;
    *) echo "Comando desconhecido: $cmd" >&2; help ;;
esac
