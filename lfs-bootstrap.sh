===============================================================================
               LFS AUTOMATION BOOTSTRAP (Cap.1-6)
===============================================================================

1. ESTRUTURA DE DIRETÓRIOS SUGERIDA

~/lfs_root/            # Diretório de root LFS temporário (equiv. a /mnt/lfs)
~/lfs_build/           # Diretório de compilação temporária (WORKDIR)
~/repo/build/          # Scripts de receitas (.sh) dos pacotes
~/repo/patch/          # Patches opcionais
~/bin/
├── pkg.sh
├── prepare.sh
├── install.sh
├── remove.sh
├── chroot-pkg.sh

~/.local/pkglogs/      # Logs de instalação
===============================================================================

2. CONFIGURAÇÃO DE VARIÁVEIS (profile ou shell)

export LFS_ROOT="$HOME/lfs_root"
export INSTALL_PREFIX="$LFS_ROOT"
export WORKDIR="$HOME/lfs_build"
export BUILDDIR="$HOME/repo/build"
export PATCHDIR="$HOME/repo/patch"
export LOGDIR="$HOME/.local/pkglogs"
export MOTOR_SCRIPT="$HOME/bin/prepare.sh"
export INSTALL_SCRIPT="$HOME/bin/install.sh"
export REMOVE_SCRIPT="$HOME/bin/remove.sh"

# Carregar
source ~/.profile

===============================================================================
3. CONCEITO DO BOOTSTRAP

- Capítulos 1-6 do LFS preparam o ambiente (diretórios, variáveis, binutils, gcc temporário, bash, etc.)
- Com pkg.sh, cada pacote será instalado automaticamente dentro de $INSTALL_PREFIX
- Todas as receitas devem respeitar a variável INSTALL_PREFIX
- Dependências são resolvidas recursivamente
- Logs detalhados ficam em $LOGDIR

===============================================================================
4. EXEMPLO DE RECEITAS (MODELO)

# gcc.sh
#!/bin/sh
NAME="gcc"
VERSION="13.2.0"
SOURCE="https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz"
PATCH=""
DEPS="gmp mpfr mpc"
PREFIX="$INSTALL_PREFIX"
BUILD="
mkdir -p build && cd build
../configure --prefix=$PREFIX --disable-multilib --enable-languages=c,c++
make -j$(nproc)
make install
"

# bash.sh
#!/bin/sh
NAME="bash"
VERSION="5.3"
SOURCE="https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz"
PATCH=""
DEPS=""
PREFIX="$INSTALL_PREFIX"
BUILD="
./configure --prefix=$PREFIX
make -j$(nproc)
make install
"

> Todas as receitas devem ter:
> NAME, VERSION, SOURCE, PATCH, DEPS, PREFIX e BUILD
> PREFIX = $INSTALL_PREFIX direciona para a partição/raiz LFS

===============================================================================
5. FLUXO DE BOOTSTRAP

# 1. Criar root LFS
mkdir -p $LFS_ROOT

# 2. Preparar pseudo-filesystems e entrar em chroot
sudo ./bin/chroot-pkg.sh $LFS_ROOT [pacotes]

# 3. Instalar pacotes de preparação (cap. 5-6)
# Exemplo de ordem:
./pkg.sh install binutils
./pkg.sh install gcc mpfr mpc gmp
./pkg.sh install bash
./pkg.sh install coreutils
./pkg.sh install file
./pkg.sh install findutils
./pkg.sh install gawk
./pkg.sh install grep
./pkg.sh install sed
./pkg.sh install tar
./pkg.sh install texinfo
./pkg.sh install xz
./pkg.sh install patch
./pkg.sh install gzip
./pkg.sh install bzip2

# 4. Entrar interativo no chroot
# Para testes ou instalação de pacotes adicionais
# Ao sair, chroot-pkg desmonta tudo automaticamente

===============================================================================
6. CONFIGURAÇÃO DE RECEITAS PARA PARTIÇÃO CUSTOMIZÁVEL

# Todas as receitas devem usar:
PREFIX="$INSTALL_PREFIX"

# Exemplo de ajuste em bash.sh
PREFIX="$INSTALL_PREFIX"
./configure --prefix=$PREFIX

# Isso garante que mesmo que mude $LFS_ROOT, todos os pacotes instalem na partição correta

===============================================================================
7. LOGS E REMOÇÃO

# Logs detalhados de cada pacote
$LOGDIR/<pacote>-<versão>-files.log

# Para remover pacotes dentro do chroot:
pkg.sh remove <pacote>

===============================================================================
8. DICAS PARA BOOTSTRAP

- Configure INSTALL_PREFIX e LFS_ROOT antes de rodar o bootstrap
- Mantenha receitas consistentes com DEPS para instalação automática
- Use ./pkg.sh rebuild para recompilar todos os pacotes se necessário
- pkg.sh + chroot-pkg.sh automatizam todo o capítulo 1-6 do LFS
- Não precisa criar nem formatar partições; apenas forneça o root ($LFS_ROOT)
- Logs detalhados permitem rastrear e remover pacotes facilmente
===============================================================================
