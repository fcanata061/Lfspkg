#!/bin/sh

install_pkg() {
    recipe="$1"

    if [ ! -f "$recipe" ]; then
        echo "Erro: receita '$recipe' não encontrada" >&2
        return 1
    fi

    # Carrega variáveis globais e receita
    . "$HOME/.profile"
    . "$recipe"

    # Resolução recursiva de dependências
    if [ -n "$DEPS" ]; then
        for dep in $DEPS; do
            dep_recipe="$BUILDDIR/$dep.sh"
            echo "==> Instalando dependência $dep"
            install_pkg "$dep_recipe" || return 1
        done
    fi

    # Compila o pacote
    echo "==> Compilando $NAME-$VERSION"
    "$MOTOR_SCRIPT" "$recipe" || {
        echo "Erro: compilação de $NAME-$VERSION falhou" >&2
        return 1
    }

    # Determina diretório fonte
    srcdir="$WORKDIR/${NAME}-${VERSION}"
    if [ ! -d "$srcdir" ]; then
        # Caso tenha baixado arquivo, tenta achar a pasta extraída
        srcdir=$(find "$WORKDIR" -mindepth 1 -maxdepth 1 -type d | head -n1)
    fi

    if [ ! -d "$srcdir" ]; then
        echo "Erro: diretório fonte não encontrado em $WORKDIR" >&2
        return 1
    fi

    echo "==> Instalando $NAME-$VERSION para /"

    # Cria log de arquivos instalados
    mkdir -p "$LOGDIR"
    logfile="$LOGDIR/${NAME}-${VERSION}-files.log"

    # Copia tudo do srcdir para /
    # rsync preserva links e permissões, e permite dry-run/debug se necessário
    rsync -a --info=progress2 "$srcdir/" / || return 1

    # Registra todos os arquivos instalados
    find "$srcdir" -type f -o -type l | sed "s|$srcdir||" | awk '{print "/" $0}' > "$logfile"

    echo "==> Instalação de $NAME-$VERSION concluída. Log em $logfile"
}

# Execução direta
if [ $# -gt 0 ]; then
    install_pkg "$1"
fi
