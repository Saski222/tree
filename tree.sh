#!/bin/bash

T_RESET="\e[0m"
T_BOLD="\e[1m"
T_BRIGHT="\e[2m"
T_ITALLIC="\e[3m"

B_EMPTY_FOLDER=""    # f07b
B_FULL_FOLDER=""     # f07c 
H_EMPTY_FOLDER=""   # f114
H_FULL_FOLDER=""    # f115

C_LINE="│"  # decoration shit

declare -i MAX_DEPTH=8      # tree max depth
declare -i MAX_ELEMENTS=8   # "branch max leaves"

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

    if [[ -n $H_FLAG ]]; then
        shopt -s dotglob
    fi

    for SUB_DIR in "${1}"/*
    do
        SUB_NAME="$(echo $SUB_DIR | awk -F '/' '{print $NF}')"

        if [ -n "$(echo $SUB_NAME | grep ' ')" ]
        then
            SUB_DIR="$(echo $SUB_DIR | sed 's=/[ ]/=\\ /=g')"
            SUB_NAME="$(echo $SUB_NAME | sed 's=/[ ]/=\\ /=g')"
        fi

       # printf "$SUB_NAME,"

        if [ -f "${SUB_DIR}" ] 
        then
            N_FILES+=1
            EXTENTIONS+="\n$(icon "${SUB_NAME}")"
        elif [ -d "${SUB_DIR}" ] 
        then
            N_DIRS+=1
        fi
    done
    
    shopt -u dotglob
    
    if [[ $N_DIRS -gt 0 ]]; then
        printf "d: $N_DIRS"
    fi
    
    if [[ $N_DIRS -gt 0 && $N_FILES -gt 0 ]]; then
        printf ", "
    fi
    
    if [[ $N_FILES -gt 0 ]]; then
        printf "f: $N_FILES ($(echo -e $EXTENTIONS | LC_ALL=C sort | uniq | tr '\n' ',' | sed "s/,$//;s/^,//"))"
    fi
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
   #if [[ -n $D_FLAG ]]; then
   #    if [[ -n $H_FLAG ]]; then
   #        R=$(du --inode -d 1 "${1}" | wc -l)
   #    else
   #        R=$(du --inode -d 1 "${1}"| grep -v "/\." | wc -l)
   #    fi
   #else
   #    if [[ -n $H_FLAG ]]; then
   #        R=$(du --inode -a -d 1 "${1}" | wc -l)
   #    else
   #        R=$(du --inode -a -d 1 "${1}" | grep -v "/\." | wc -l)
   #    fi
   #fi
    if [[ -n $H_FLAG ]]; then
        R=$(du --inode -a -d 1 "${1}" | wc -l)
    else
        R=$(du --inode -a -d 1 "${1}" | grep -v "/\." | wc -l)
    fi

    echo $(($(($R)) - 1))
}

# main, does all the things
function recursive()
{
    declare -i ELEMENTS=0
    
    # activate a flag for hidden shit
    if [[ -n $H_FLAG ]]; then
        shopt -s dotglob
    fi
   
    # loop around f/d(s) inside dir
    for DIR in "${1}"/*
    do
        NAME="$(echo $DIR | awk -F '/' '{print $NF}')"

        if [ -n "$(echo $NAME | grep ' ')" ]
        then
            DIR="$(echo $DIR | sed 's=/[ ]/=\\ /=g')"
            NAME="$(echo $NAME | sed 's=/[ ]/=\\ /=g')"
        fi


        if [ -f "$DIR" ] # FILE
        then 
            # check if only directory mode
            if [[ -n $D_FLAG ]]; then
                continue
            fi

            # print necesary tabulation
            tabs $2 
            
            # check if file is hiden ".fileName"
            if [[ -n "$(echo $NAME | grep "^\..")" ]]; then
                printf "$T_BRIGHT"
            else
                printf "$T_RESET"
            fi
            
            # print file icon and name
            printf "$(icon "${NAME}") $T_ITALLIC$NAME$T_RESET\n"
        elif [ -d "$DIR" ] # DIR
        then
            # print necesary tabulation
            tabs $2 
            
            # count number of elements inside file
            ELEMENTS=$(count_elements "${DIR}")

            # check if file is empty
            if [[ $ELEMENTS -eq 0 ]]; then
                # check if file is hiden
                if [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                    printf "${T_RESET}$B_EMPTY_FOLDER $NAME"
                else
                    printf "${T_BRIGHT}$H_EMPTY_FOLDER $NAME"
                fi

                # check if meta flag is on
                if [[ -n $M_FLAG ]]; then
                    printf "  ${T_BRIGHT}󰟢" # " 'empty'" # 󰟢 f07e2
                fi
                printf "\n"
                
                #printf " ${T_BRIGHT}\n" # f10c 󰟢 f07e2
            else 
                # check if has to many elements to show
                if [[ $ELEMENTS -gt $MAX_ELEMENTS ]]; then
                    # check if file is hide 
                    # !TODO this can be taken out from here back (code repetition)
                    if [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                        printf "${T_RESET}$B_EMPTY_FOLDER $NAME"
                    else
                        printf "${T_BRIGHT}$H_EMPTY_FOLDER $NAME"
                    fi
                elif [[ -z $(echo "$NAME" | grep "^\..") ]]; then
                    printf "${T_RESET}$B_FULL_FOLDER $NAME"
                else
                    printf "${T_BRIGHT}$H_FULL_FOLDER $NAME"
                fi 
                
                # check if we have reached max_d or to many elements to show
                if [[ $MAX_DEPTH -lt $2 || $ELEMENTS -gt $MAX_ELEMENTS ]]
                then
                    if [[ -z $M_FLAG ]]; then
                        printf "  ${T_BRIGHT}${ELEMENTS} element(s)\n" # f0da
                    else
                        printf "  ${T_BRIGHT}$(mine_info "${DIR}")\n" # f0da
                    fi
                    continue
                fi
                
                # check if meta flag is on
                if [[ -z $M_FLAG ]]; then
                    printf "  ${T_BRIGHT}${ELEMENTS} element(s)\n" # f0d7
                else
                    printf "  ${T_BRIGHT}$(mine_info "${DIR}")\n" # f0d7
                fi
                
                # go inside directory and recursively repeat
                recursive "${DIR}" $(($2+1))
            fi   
        else
                # unkown (normaly happens f/d doesn't exist > you fucked up)
            echo "unk: $NAME; dir: $DIR" 
        fi
    done
    
    # deactivate the flag for hidden shit
    shopt -u dotglob
     
    return 1
}

function help ()
{
    # -[amd]|-[xy] \d+ ∞
    echo -e "Usage: tree [-[amd]|-[xy] [0-9]+] [dir]"
    echo -e "  e.g: tree -a 'show tree, with hiden folders'"
    echo -e "  e.g: tree -d -x 3 -m 'show tree, with only directories, MAX_DEPTH=3, show some metadata of directories'"
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

while test $# -gt 0; do
    ARG=$1
    shift
    case "$ARG" in
        -h | --help) help;;
        -a) H_FLAG="-A";; 
        -d) D_FLAG="1";;
        -m | --meta) M_FLAG="1";;
        -x | --depth) MAX_DEPTH=$1; shift;;
        -y | --elements) MAX_ELEMENTS=$1; shift;; 
        *) MY_PWD="$ARG"
    esac
done  

# MY_PATH SETUP
if [[ -n $MY_PWD ]]; then  # User Input DIR
    # Check if path is relative and convert to absolute
    if [[ -z $(echo $MY_PWD | grep -E '^/') ]]; then
        MY_PWD="$(pwd)$(echo "/$MY_PWD" | sed "s|^//|/|")"
    fi
    
    # Check if exist
    if [[ ! -d $MY_PWD ]]; then
        echo "tree: error: directory not found"
        exit 0
    fi
    # /path/to/my/directory
    MY_PWD="$(echo $MY_PWD | sed "s|/$||")"
else     # User actual dir 
    MY_PWD="$(pwd)"
fi

printf "$B_FULL_FOLDER "
echo $MY_PWD | awk -F '/' '{print $NF}'

recursive "$MY_PWD" 1

