#!/bin/sh

log() {
    prefix="$1"
    shift
    echo "[$prefix] $*"
}

install_pkg() {
    recipe="$1"

    if [ ! -f "$recipe" ]; then
        log FAIL "Receita '$recipe' não encontrada"
        return 1
    fi

    . "$HOME/.profile"
    . "$recipe"

    log INFO "Iniciando instalação de $NAME-$VERSION"

    # Resolução recursiva de dependências
    if [ -n "$DEPS" ]; then
        for dep in $DEPS; do
            dep_recipe="$BUILDDIR/$dep.sh"
            log INFO "Instalando dependência $dep"
            install_pkg "$dep_recipe" || {
                log FAIL "Falha ao instalar dependência $dep"
                return 1
            }
            log OK "Dependência $dep instalada"
        done
    fi

    # Compilação
    log INFO "Compilando $NAME-$VERSION"
    "$MOTOR_SCRIPT" "$recipe" || {
        log FAIL "Compilação de $NAME-$VERSION falhou"
        return 1
    }
    log OK "Compilação concluída"

    # Determina diretório fonte
    srcdir="$WORKDIR/${NAME}-${VERSION}"
    if [ ! -d "$srcdir" ]; then
        srcdir=$(find "$WORKDIR" -mindepth 1 -maxdepth 1 -type d | head -n1)
    fi
    [ -d "$srcdir" ] || { log FAIL "Diretório fonte não encontrado"; return 1; }

    # Instalação real
    log INFO "Instalando $NAME-$VERSION para /"
    logfile="$LOGDIR/${NAME}-${VERSION}-files.log"
    mkdir -p "$LOGDIR"

    # Copia usando rsync
    rsync -a --info=progress2 "$srcdir/" / || { log FAIL "Falha na cópia para /"; return 1; }

    # Registra arquivos instalados
    find "$srcdir" -type f -o -type l | sed "s|$srcdir||" | awk '{print "/" $0}' > "$logfile"

    log OK "Instalação de $NAME-$VERSION concluída. Log em $logfile"
}

# Execução direta
if [ $# -gt 0 ]; then
    install_pkg "$1"
fi
