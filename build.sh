#!/bin/sh

prepare() {
    keep="no"
    only_download="no"

    # processa opções
    while [ $# -gt 0 ]; do
        case "$1" in
            --keep-workdir)   keep="yes"; shift ;;
            --only-download)  only_download="yes"; shift ;;
            *) break ;;
        esac
    done

    recipe="$1"

    if [ ! -f "$recipe" ]; then
        echo "Erro: receita '$recipe' não encontrada" >&2
        return 1
    fi

    # Carrega variáveis da receita
    . "$recipe"

    workdir="${WORKDIR:-./work}"

    if [ "$keep" = "no" ]; then
        echo "==> Limpando $workdir"
        rm -rf "$workdir"
    fi
    mkdir -p "$workdir"

    echo "==> Preparando $NAME-$VERSION"

    srcfile="$workdir/${NAME}-${VERSION}.src"

    case "$SOURCE" in
        git:* | http*://*.git)
            echo "==> Clonando repositório git"
            git clone "$SOURCE" "$workdir/${NAME}-${VERSION}" || return 1
            srcdir="$workdir/${NAME}-${VERSION}"
            ;;
        http*://* | ftp*://*)
            echo "==> Baixando arquivo"
            curl -L "$SOURCE" -o "$srcfile" || return 1

            echo "==> Extraindo"
            case "$srcfile" in
                *.tar.gz|*.tgz) tar -xzf "$srcfile" -C "$workdir" ;;
                *.tar.bz2)      tar -xjf "$srcfile" -C "$workdir" ;;
                *.tar.xz)       tar -xJf "$srcfile" -C "$workdir" ;;
                *.zip)          unzip -q "$srcfile" -d "$workdir" ;;
                *) echo "Formato desconhecido: $srcfile" >&2; return 1 ;;
            esac

            srcdir=$(find "$workdir" -mindepth 1 -maxdepth 1 -type d | head -n1)
            ;;
        *)
            echo "SOURCE não suportado: $SOURCE" >&2
            return 1
            ;;
    esac

    echo "==> Diretório fonte: $srcdir"

    if [ "$only_download" = "yes" ]; then
        echo "==> Apenas download concluído (sem patch/build)"
        return 0
    fi

    if [ -n "$PATCH" ] && [ -f "$PATCH" ]; then
        echo "==> Aplicando patch $PATCH"
        (cd "$srcdir" && patch -p1 < "../$PATCH") || return 1
    fi

    if [ -n "$BUILD" ]; then
        echo "==> Compilando"
        (cd "$srcdir" && sh -c "$BUILD") || return 1
    else
        echo "Nenhum comando BUILD definido na receita" >&2
    fi
}

# Execução direta
# Exemplos:
#   ./motor.sh recipe.sh
#   ./motor.sh --keep-workdir recipe.sh
#   ./motor.sh --only-download recipe.sh
#   ./motor.sh --keep-workdir --only-download recipe.sh
if [ $# -gt 0 ]; then
    prepare "$@"
fi
