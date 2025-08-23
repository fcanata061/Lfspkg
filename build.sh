#!/bin/sh

prepare() {
    recipe="$1"

    if [ ! -f "$recipe" ]; then
        echo "Erro: receita '$recipe' não encontrada" >&2
        return 1
    fi

    # Carrega variáveis do .profile e da receita
    . "$HOME/.profile"
    . "$recipe"

    # Garante diretórios
    mkdir -p "$WORKDIR" "$LOGDIR"

    echo "==> Preparando $NAME-$VERSION"

    # Sempre começa limpo (pode combinar com --keep-workdir se quiser)
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
        echo "==> Compilando"
        (cd "$srcdir" && sh -c "$BUILD") || return 1

        # registra arquivos instalados (simples: tudo modificado em /usr)
        logfile="$LOGDIR/${NAME}-${VERSION}-files.log"
        find /usr -newermt "$(date -r "$srcfile" '+%Y-%m-%d %H:%M:%S')" > "$logfile"
        echo "==> Arquivos instalados registrados em $logfile"
    else
        echo "Nenhum comando BUILD definido na receita" >&2
    fi
}

if [ $# -gt 0 ]; then
    prepare "$1"
fi
