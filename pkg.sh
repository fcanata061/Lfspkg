#!/bin/sh

. "$HOME/.profile"

# ===== Cores ANSI =====
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

log() {
    prefix="$1"
    shift
    case "$prefix" in
        INFO)  echo -e "${BLUE}[$prefix] $*${RESET}" ;;
        OK)    echo -e "${GREEN}[$prefix] $*${RESET}" ;;
        FAIL)  echo -e "${RED}[$prefix] $*${RESET}" ;;
        WARN)  echo -e "${YELLOW}[$prefix] $*${RESET}" ;;
        *)     echo "[$prefix] $*" ;;
    esac
}

# Barra de progresso simples
progress_bar() {
    current="$1"
    total="$2"
    width=30
    filled=$((current * width / total))
    empty=$((width - filled))
    printf "["
    for i in $(seq 1 $filled); do printf "="; done
    for i in $(seq 1 $empty); do printf " "; done
    printf "] %d%%\r" $((current*100/total))
}

help() {
    cat <<EOF
Uso: pkg.sh <comando> [pacote]

Comandos:
  install <pacote>     - Instala o pacote (resolve dependências recursivas)
  remove <pacote>      - Remove o pacote usando log de instalação
  search <termo>       - Busca pacotes disponíveis no BUILDDIR
  info <pacote>        - Mostra informações do pacote (receita + log)
  rebuild              - Recompila todo o sistema
  help                 - Mostra este help
EOF
}

# ===== Funções principais =====

install_pkg() {
    pkg="$1"
    recipe="$BUILDDIR/$pkg.sh"

    [ -f "$recipe" ] || { log FAIL "Pacote não encontrado: $pkg"; return 1; }
    . "$recipe"

    log INFO "Iniciando instalação de $NAME-$VERSION"

    # Dependências recursivas
    if [ -n "$DEPS" ]; then
        total_dep=$(echo $DEPS | wc -w)
        count_dep=0
        for dep in $DEPS; do
            count_dep=$((count_dep+1))
            echo -ne "${BLUE}[$pkg] Instalando dependência $dep ($count_dep/$total_dep)${RESET}\r"
            install_pkg "$dep" || { log FAIL "Falha ao instalar dependência $dep"; return 1; }
            echo -ne "${GREEN}[$pkg] Dependência $dep instalada ($count_dep/$total_dep)${RESET}\n"
        done
    fi

    # Compilação
    log INFO "Compilando $NAME-$VERSION"
    "$MOTOR_SCRIPT" "$recipe" || { log FAIL "Falha na compilação de $NAME-$VERSION"; return 1; }
    log OK "Compilação concluída"

    # Determina diretório fonte
    srcdir="$WORKDIR/${NAME}-${VERSION}"
    [ -d "$srcdir" ] || srcdir=$(find "$WORKDIR" -mindepth 1 -maxdepth 1 -type d | head -n1)
    [ -d "$srcdir" ] || { log FAIL "Diretório fonte não encontrado"; return 1; }

    # Instalação real com barra de progresso
    log INFO "Instalando $NAME-$VERSION para /"
    mkdir -p "$LOGDIR"
    files=$(find "$srcdir" -type f -o -type l)
    total_files=$(echo "$files" | wc -l)
    count=0

    for f in $files; do
        dest="/${f#$srcdir/}"
        mkdir -p "$(dirname "$dest")"
        cp -a "$f" "$dest"
        count=$((count+1))
        progress_bar "$count" "$total_files"
    done
    echo ""

    # Log de arquivos instalados
    logfile="$LOGDIR/${NAME}-${VERSION}-files.log"
    find "$srcdir" -type f -o -type l | sed "s|$srcdir||" | awk '{print "/" $0}' > "$logfile"
    log OK "Instalação de $NAME-$VERSION concluída. Log em $logfile"
}

remove_pkg() {
    recipe="$BUILDDIR/$1.sh"
    [ -f "$recipe" ] || { log FAIL "Pacote não encontrado: $1"; return 1; }
    log INFO "Removendo pacote $1"
    "$REMOVE_SCRIPT" "$recipe" || { log FAIL "Falha na remoção de $1"; return 1; }
    log OK "Remoção de $1 concluída"
}

search_pkg() {
    term="$1"
    find "$BUILDDIR" -type f -name "*.sh" | xargs -n1 basename | grep "$term"
}

info_pkg() {
    recipe="$BUILDDIR/$1.sh"
    [ -f "$recipe" ] || { log FAIL "Pacote não encontrado: $1"; return 1; }
    log INFO "Informações do pacote $1"
    grep -E "^(NAME|VERSION|SOURCE|DEPS|PATCH|BUILD)" "$recipe"
    echo "Arquivos instalados (log): $LOGDIR/$1-*.log"
}

rebuild_system() {
    pkgs=$(ls "$BUILDDIR"/*.sh | xargs -n1 basename | sed 's/\.sh$//')
    total=$(echo "$pkgs" | wc -w)
    count=0
    log INFO "Recompilando todo o sistema"
    for pkg in $pkgs; do
        count=$((count+1))
        echo -ne "${BLUE}[Rebuild] Instalando $pkg ($count/$total)${RESET}\r"
        install_pkg "$pkg" || log FAIL "Falha ao recompilar $pkg"
        echo -ne "${GREEN}[Rebuild] Pacote $pkg concluído ($count/$total)${RESET}\n"
    done
    log OK "Recompilação completa"
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
    *) log FAIL "Comando desconhecido: $cmd"; help ;;
esac
