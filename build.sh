#!/bin/sh

prepare() {
    recipe="$1"

    if [ ! -f "$recipe" ]; then
        echo "Erro: receita '$recipe' não encontrada" >&2
        return 1
    fi

    # Carrega variáveis globais e receita
    . "$HOME/.profile"
    . "$recipe"

    mkdir -p "$WORKDIR" "$LOGDIR"

    echo "==> Preparando $NAME-$VERSION"
    rm -rf "$WORKDIR"
    mkdir -p "$WORKDIR"

    srcfile="$WORKDIR/${NAME}-${VERSION}.src"

    case "$SOURCE" in
        git:* | http*://*.git)
            echo "==> Clonando repositório git"
            git clone "$SOURCE" "$WORKDIR/${NAME}-${VERSION}" || return 1
            srcdir="$WORKDIR/${NAME}-${VERSION}"
            ;;
        http*://* | ftp*://*)
            echo "==> Baixando arquivo"
            curl -L "$SOURCE" -o "$srcfile" || return 1

            echo "==> Extraindo"
            case "$srcfile" in
                *.tar.gz|*.tgz) tar -xzf "$srcfile" -C "$WORKDIR" ;;
                *.tar.bz2)      tar -xjf "$srcfile" -C "$WORKDIR" ;;
                *.tar.xz)       tar -xJf "$srcfile" -C "$WORKDIR" ;;
                *.zip)          unzip -q "$srcfile" -d "$WORKDIR" ;;
                *) echo "Formato desconhecido: $srcfile" >&2; return 1 ;;
            esac

            srcdir=$(find "$WORKDIR" -mindepth 1 -maxdepth 1 -type d | head -n1)
            ;;
        *)
            echo "SOURCE não suportado: $SOURCE" >&2
            return 1
            ;;
    esac

    echo "==> Diretório fonte: $srcdir"

    if [ -n "$PATCH" ] && [ -f "$PATCH" ]; then
        echo "==> Aplicando patch $PATCH"
        (cd "$srcdir" && patch -p1 < "$PATCH") || return 1
    fi

    if [ -n "$BUILD" ]; then
        echo "==> Gerando snapshot antes da instalação"
        before="$WORKDIR/.before.lst"
        after="$WORKDIR/.after.lst"
        logfile="$LOGDIR/${NAME}-${VERSION}-files.log"

        find /usr /etc /opt /var -type f -o -type l 2>/dev/null | sort > "$before"

        echo "==> Compilando e instalando"
        (cd "$srcdir" && sh -c "$BUILD") || return 1

        echo "==> Gerando snapshot depois da instalação"
        find /usr /etc /opt /var -type f -o -type l 2>/dev/null | sort > "$after"

        echo "==> Gravando diferenças em $logfile"
        comm -13 "$before" "$after" > "$logfile"
        echo "==> Instalação concluída. Arquivos rastreados: $(wc -l < "$logfile")"
    else
        echo "Nenhum comando BUILD definido na receita" >&2
    fi
}

# Execução direta
if [ $# -gt 0 ]; then
    prepare "$1"
fi
