#!/bin/bash

readonly ROOT_UID=0
readonly MAX_DELAY=20 # max delay for user to enter root password

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$UID" -eq "$ROOT_UID" ]]; then
  BACKGROUND_DIR="/usr/share/backgrounds"
else
  BACKGROUND_DIR="$HOME/.local/share/backgrounds"
fi

#COLORS
CDEF=" \033[0m"                               # default color
CCIN=" \033[0;36m"                            # info color
CGSC=" \033[0;32m"                            # success color
CRER=" \033[0;31m"                            # error color
CWAR=" \033[0;33m"                            # waring color
b_CDEF=" \033[1;37m"                          # bold default color
b_CCIN=" \033[1;36m"                          # bold info color
b_CGSC=" \033[1;32m"                          # bold success color
b_CRER=" \033[1;31m"                          # bold error color
b_CWAR=" \033[1;33m"                          # bold warning color

# echo like ...  with  flag type  and display message  colors
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;    # print success message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;    # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;    # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;    # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

adicionar_backgrounds() {
  cp -a --no-preserve=ownership ${REPO_DIR}/User_Backgrounds/* ${BACKGROUND_DIR}/User_Backgrounds
}

install() {
  prompt -i "\n * Install User_Backgrounds in ${BACKGROUND_DIR}... "
  mkdir -p ${BACKGROUND_DIR}/User_Backgrounds
  adicionar_backgrounds
}

uninstall() {
  prompt -i "\n * Uninstall User_Backgrounds... "
  [[ -d ${BACKGROUND_DIR}/User_Backgrounds ]] && rm -rf ${BACKGROUND_DIR}/User_Backgrounds
}

if [[ "${uninstall}" != 'true' ]]; then
  install
else
  uninstall
fi

prompt -s "Finished!"