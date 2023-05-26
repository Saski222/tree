#!/bin/bash

T_RESET="\e[0m"
T_BOLD="\e[1m"
T_BRIGHT="\e[2m"
T_ITALLIC="\e[3m"

B_EMPTY_FOLDER=""    # f07b
B_FULL_FOLDER=""     # f07c 
H_EMPTY_FOLDER=""   # f114
H_FULL_FOLDER=""    # f115

B_FILE="${T_ITALLIC}"             # f15c

declare -i MAX_DEPTH=8
declare -i MAX_ELEMENTS=8

H_FLAG="" # -A = almost-all; 
D_FLAG="NOT_NULL" # "" or "NOT_NULL" onli directories or all
M_FLAG="" # metadata flag

function icon ()
{    
    case "$1" in
        *.txt)  echo '󰈙' ;; # f0219
        *.zip)  echo '' ;; # f1c6
        *.sh)   echo '' ;; # e795
        *.py)   echo '' ;; # e606
        *.c)    echo '' ;; # e61e
        *.cpp)  echo '' ;; # e61d
        *.h)    echo '' ;; # eac4
        *.java) echo '' ;; # e256
        *.json) echo '' ;; # e60b
        *.png | *.jpeg) echo "󰈟" ;; # f021f
        *.pdf)  echo '' ;; # eaeb
        *.mp3 | *.wav) echo '󰈣' ;; # f0223
        *.mp4)  echo '󰈫' ;; # f022b
        .*)     echo '' ;; # ea7b
        *)      echo '󰈔' ;; # f0214
    esac
}

function mine_info() 
{
    declare -i N_FILES=0
    declare -i N_DIRS=0

    EXTENTIONS=""

    if [[ ! -z $H_FLAG ]]; then
        shopt -s dotglob
    fi

    for SUB_DIR in $1*
    do
        SUB_NAME="$(echo $SUB_DIR | awk -F '/' '{print $NF}')"

        if [ -f $SUB_DIR ] 
        then
            N_FILES+=1
            EXTENTIONS+="\n$(icon $SUB_NAME)"
        elif [ -d $SUB_DIR ] 
        then
            N_DIRS+=1
        fi
    done
    
    shopt -u dotglob
    
    if [[ $N_DIRS -gt 0 ]]; then
        printf "dirs: $N_DIRS; "
    fi
    
    if [[ $N_FILES -gt 0 ]]; then
        printf "files: $N_FILES ($(echo -e $EXTENTIONS | LC_ALL=C sort | uniq | tr '\n' ',' | sed "s/,$//;s/^,//"))"
    fi
}

function recursive()
{
    declare -i ELEMENTS=0

    if [[ ! -z $H_FLAG ]]; then
        shopt -s dotglob
    fi
    
    for DIR in "${1}"/*
    do
        NAME="$(echo $DIR | awk -F '/' '{print $NF}')"
        if [ ! -z "$(echo $NAME | grep ' ')" ]
        then
            DIR="$(echo $DIR | sed 's=/[ ]/=\\ /=g')"
        fi

        if [ -f "$DIR" ] 
        then
            if [[ -z $D_FLAG ]]; then
                continue
            fi
            for ((i = 0; i < $2; i++)); do
                printf "| "
            done

                
            if [[ ! -z "$(echo $NAME | grep "^\..")" ]]; then
                printf "$T_BRIGHT"
            else
                printf "$T_RESET"
            fi

            printf "$(icon $NAME) $T_ITALLIC$NAME\n"
        elif [ -d "$DIR" ] 
        then
            if [[ -z $D_FLAG ]]; then
                ELEMENTS=$(ls -p $H_FLAG "$DIR" | grep '/' | wc -l)
            else  
                ELEMENTS=$(ls $H_FLAG "$DIR" | wc -l)
            fi
            
            for ((i = 0; i < $2; i++)); do
                printf "| "
            done

            if [[ $ELEMENTS -eq 0 ]]; then  
                if [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                    printf "${T_RESET}$B_EMPTY_FOLDER $NAME"
                else
                    printf "${T_BRIGHT}$H_EMPTY_FOLDER $NAME"
                fi
                
                if [[ ! -z $M_FLAG ]]; then
                    printf "  \"empty\"" # f0da
                fi
                printf "\n"
            else 
                if [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                    printf "${T_RESET}$B_FULL_FOLDER $NAME"
                else
                    printf "${T_BRIGHT}$H_FULL_FOLDER $NAME"
                fi 

                if [[ $MAX_DEPTH -lt $2 || $ELEMENTS -gt $MAX_ELEMENTS ]]; then
                    if [[ -z $M_FLAG ]]; then
                        printf "  ${ELEMENTS} element(s) inside\n"
                    else
                        printf "  $(mine_info "${DIR}/")\n"
                    fi
                    continue
                fi
                
                if [[ ! -z $M_FLAG ]]; then
                    printf "  $(mine_info "${DIR}/")"
                fi

                printf "\n"
                recursive "${DIR}" $(($2+1))
            fi   
        else
            echo "unk: $NAME; dir: $DIR" 
        fi
    done

    shopt -u dotglob
    
    return 1
}

function help ()
{
    echo -e "Usage: tree [option (arg)]"
    echo -e "  -a:\n\tshow hiden files/directories"
    echo -e "  -d:\n\thide files"
    echo -e "  -m --meta:\n\tshow more info about unopened folders"
    echo -e "  -x # || --depth #:\n\tgoes # directories depth. default = ${MAX_DEPTH}"
    echo -e "  -y # || --elements #:\n\tshows file contents if it has less than # number of elements. default = ${MAX_ELEMENTS}"

    exit 0
}

MY_PWD="$(pwd)"

while test $# -gt 0; do
    ARG=$1
    shift
    case "$ARG" in
        -h | --help) help;;
        -a) H_FLAG="-A";; 
        -d) D_FLAG="";;
        -m | --meta) M_FLAG="yeah";;
        -x | --depth) MAX_DEPTH=$1; shift;;
        -y) MAX_ELEMENTS=$1; shift;;
        -elements) MAX_ELEMENTS=$1; shift;; 
        *) MY_PWD="$ARG"
    esac
done  

printf "$B_FULL_FOLDER "
echo $MY_PWD | awk -F '/' '{print $NF}'

recursive "$MY_PWD" 1
