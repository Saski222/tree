#!/bin/bash

T_RESET="\e[0m"
T_BOLD="\e[1m"
T_BRIGHT="\e[2m"
T_ITALLIC="\e[3m"

B_CLOSED_FOLDER=""    # f07b
B_OPEN_FOLDER=""     # f07c 
H_CLOSED_FOLDER=""   # f114
H_OPEN_FOLDER=""    # f115

C_LINE="│"  # decoration shit

declare -i MAX_DEPTH=8      # tree max depth
declare -i MAX_ELEMENTS=16  # "branch max leaves"

MY_PWD="" # 'root' folder

H_FLAG="" # show hiden files (ls -A (-A = almost-all)) 
D_FLAG="" # show directories only
M_FLAG="" # show metadata 

# returns the icon to the corresponding file type*
# type*: based on the file name (myFile.txt -> text file...)
function icon ()
{    
    case "${1}" in
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

# looks inside directory and takes info about what is inside
function mine_info() 
{
    declare -i N_FILES=0
    declare -i N_DIRS=0

    EXTENTIONS=""

    [[ -n $H_FLAG ]] && shopt -s dotglob

    for SUB_DIR in "${1}"/*
    do
        SUB_NAME="$(echo $SUB_DIR | awk -F '/' '{print $NF}')"

        if [[ -n "$(echo $SUB_NAME | grep ' ')" ]]
        then
            SUB_DIR="$(echo $SUB_DIR | sed 's=/[ ]/=\\ /=g')"
            SUB_NAME="$(echo $SUB_NAME | sed 's=/[ ]/=\\ /=g')"
        fi

        if [[ -f "${SUB_DIR}" ]] 
        then
            N_FILES+=1
            EXTENTIONS+="\n$(icon "${SUB_NAME}")"
        elif [[ -d "${SUB_DIR}" ]] 
        then
            N_DIRS+=1
        fi
    done
    
    shopt -u dotglob

    [[ 0 -lt $N_DIRS ]] && printf "d: $N_DIRS" && [ $N_FILES -gt 0 ] && printf ", "
    
    [[ 0 -lt $N_FILES ]] && printf "f: $N_FILES ($(echo -e $EXTENTIONS | LC_ALL=C sort | uniq | tr '\n' ',' | sed "s/,$//;s/^,//"))"
}

function tabs() {
    printf "$T_BRIGHT"
    for ((i = 0; i < $1; i++)); do
        printf "$C_LINE  " # •
    done
    printf "$T_RESET"
}

# counts the total number of element inside directory
function count_elements()
{
    R="1"

    if [[ -n $H_FLAG ]]; then
        R=$(du --inode -a -d 1 "${1}" | wc -l)
    else
        R=$(du --inode -a -d 1 "${1}" | grep -v "/\." | wc -l)
    fi

    echo $(($(($R)) - 1))
}

function generate_list_of_elements() 
{
    # activate a flag for hidden shit
    if [[ -n $H_FLAG ]]; then
        shopt -s dotglob
    fi

    # First dirs
    for D in "${1}"/*
    do
        [[ -d "${D}" ]] && echo "${D}" | sed 's/[ ]/\/\//g'
    done
    
    # Second files
    for F in "${1}"/*
    do
        [[ -f "${F}" ]] && echo "${F}" | sed 's/[ ]/\/\//g'
    done
    
    # deactivate the flag for hidden shit
    shopt -u dotglob
}

# main, does all the things
function recursive()
{
    declare -i ELEMENTS=0

    # loop around f/d(s) inside dir
    for DIR in $(generate_list_of_elements "${1}") # "${1}"/*
    do
        DIR="$(echo $DIR | sed 's/\/\//\ /g')"
        NAME="$(echo $DIR | awk -F '/' '{print $NF}')"

        if [[ -f "$DIR" ]] # FILE
        then 
            # check if only directory mode
            [[ -n $D_FLAG ]] && continue

            # print necesary tabulation
            tabs $2 
            
            # check if file is hiden ".fileName"
            [[ -n "$(echo $NAME | grep "^\..")" ]] && printf "$T_BRIGHT" || printf "$T_RESET"
            
            # print file icon and name
            printf "$(icon "${NAME}") $T_ITALLIC$NAME$T_RESET\n"
        elif [[ -d "$DIR" ]] # DIR
        then
            # print necesary tabulation
            tabs $2 
            
            # count number of elements inside file
            ELEMENTS=$(count_elements "${DIR}")

            # check if file is empty
            if [[ $ELEMENTS -eq 0 ]]; then
                # check if file is hiden
                if [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                    printf "${T_RESET}$B_CLOSED_FOLDER $NAME"
                else
                    printf "${T_BRIGHT}$H_CLOSED_FOLDER $NAME"
                fi

                # check if meta flag is on
                [[ -n $M_FLAG ]] && printf "  ${T_BRIGHT}󰟢" # f07e2

                printf "\n"
            else 
                # check if has to many elements to show
                if [[ $MAX_ELEMENTS -lt $ELEMENTS ]]; then
                    # check if file is hide 
                    if [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                        printf "${T_RESET}$B_CLOSED_FOLDER $NAME"
                    else
                        printf "${T_BRIGHT}$H_CLOSED_FOLDER $NAME"
                    fi
                else
                    if [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                        printf "${T_RESET}$B_OPEN_FOLDER $NAME"
                    else
                        printf "${T_BRIGHT}$H_OPEN_FOLDER $NAME"
                    fi 
                fi
                
                # check if meta flag is on
                if [[ -z $M_FLAG ]]; then
                    printf "  ${T_BRIGHT}${ELEMENTS} element(s)\n" # f0d7
                else
                    printf "  ${T_BRIGHT}$(mine_info "${DIR}")\n" # f0d7
                fi

                # check if we have reached max_d or to many elements to show
                [[ $MAX_DEPTH -lt $2 || $MAX_ELEMENTS -lt $ELEMENTS ]] && continue
                
                # go inside directory and recursively repeat
                recursive "${DIR}" $(($2+1))
            fi   
        else
            # unkown (normaly happens f/d doesn't exist > you fucked up)
            echo "unk: $NAME; dir: $DIR" 
        fi
    done
     
    return 1
}

function help ()
{
    # -[amd]|-[xy] \d+ ∞
    echo -e "Usage: tree [-[amd]|-[xy] [0-9]+] [dir]"
    echo -e "  e.g: tree -a 'show tree, with hiden folders'"
    echo -e "  e.g: tree -d -x 3 -m 'show tree, with only directories, MAX_DEPTH=3, show some metadata of directories'"
    echo -e "  e.g: tree -mad 'show tree, only directories, hiden directories and meta about them'"
    echo -e "Flags:"
    echo -e "  behaviour:"
    echo -e "    -a,\n      show hiden files/directories."
    echo -e "    -d,\n      hide files."
    echo -e "    -m --meta,\n      show more info about unopened folders."
    echo -e "  distance:"
    echo -e "    -x #, --depth #\n      goes # directories depth. default = ${MAX_DEPTH}."
    echo -e "    -y #, --elements #\n      shows file contents if it has less than # number of elements. default = ${MAX_ELEMENTS}."
    exit 0
}

function concatenated_flags ()
{
    for F in $(echo "$1" | tr -d '-' | grep -o .)
    do
        case "$F" in
            a) H_FLAG="1";;
            d) D_FLAG="1";;
            m) M_FLAG="1";;
            *) echo "tree: error: unkown flag '$F', do 'tree -h' for help" && exit 0;;
        esac   
    done 
}

while test $# -gt 0; do
    ARG=$1
    shift
    case "$ARG" in
        -h | --help) help;;
        -a) H_FLAG="1";; 
        -d) D_FLAG="1";;
        -m | --meta) M_FLAG="1";;
        -x | --depth) MAX_DEPTH=$1; shift;;
        -y | --elements) MAX_ELEMENTS=$1; shift;; 
        -*) concatenated_flags $ARG;; # echo "tree: error: unkown flag '$ARG', do 'tree -h' for help" && exit 0;;
        *) MY_PWD="$ARG"
    esac
done  

# MY_PATH SETUP
if [[ -n $MY_PWD ]]; then  # User Input DIR
    # Check if path is relative and convert to absolute
    [[ -z $(echo $MY_PWD | grep -E '^/') ]] && MY_PWD="$(pwd)$(echo "/$MY_PWD" | sed "s|^//|/|")"
    
    # Check if exist
    [[ ! -d $MY_PWD ]] && echo "tree: error: directory not found" && exit 0

    # /path/to/my/directory
    MY_PWD="$(echo $MY_PWD | sed "s|/$||")"
else     # User actual dir 
    MY_PWD="$(pwd)"
fi

#   echo $MY_PWD
#  echo $MAX_ELEMENTS
#  echo $MAX_DEPTH

#   echo "d:'$D_FLAG'"
#   echo "h:'$H_FLAG'"
#   echo "m:'$M_FLAG'"


printf "$B_OPEN_FOLDER "
echo $MY_PWD | awk -F '/' '{print $NF}'

recursive "$MY_PWD" 1

