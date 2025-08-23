#!/bin/sh

remove() {
    recipe="$1"

    if [ ! -f "$recipe" ]; then
        echo "Erro: receita '$recipe' não encontrada" >&2
        return 1
    fi

    . "$HOME/.profile"
    . "$recipe"

    logfile="$LOGDIR/${NAME}-${VERSION}-files.log"

    if [ ! -f "$logfile" ]; then
        echo "Erro: log não encontrado em $logfile" >&2
        return 1
    fi

    echo "==> Removendo pacote $NAME-$VERSION"

    # Remove arquivos na ordem inversa
    tac "$logfile" | while IFS= read -r f; do
        if [ -e "$f" ] || [ -L "$f" ]; then
            echo "  - Removendo $f"
            rm -f "$f"
        fi
    done

    # Remove diretórios vazios do mais profundo para o mais alto
    echo "==> Limpando diretórios vazios"
    tac "$logfile" | while IFS= read -r f; do
        dir=$(dirname "$f")
        while [ "$dir" != "/" ]; do
            if [ -d "$dir" ] && [ "$(ls -A "$dir")" = "" ]; then
                echo "  - Removendo diretório vazio $dir"
                rmdir "$dir"
            fi
            dir=$(dirname "$dir")
        done
    done

    echo "==> Limpando log $logfile"
    rm -f "$logfile"
}

# Execução direta
if [ $# -gt 0 ]; then
    remove "$1"
fi
