#!/bin/bash

T_RESET="\e[0m"
T_BOLD="\e[1m"
T_BRIGHT="\e[2m"
T_ITALLIC="\e[3m"
T_UNDERLINED="\e[4m"

B_CLOSED_FOLDER=""     # f07b
B_OPEN_FOLDER=""       # f07c 
H_CLOSED_FOLDER=""     # f114
H_OPEN_FOLDER=""       # f115

C_LINE="│"  # decoration shit

declare -i MAX_DEPTH=8      # tree max depth
declare -i MAX_ELEMENTS=16  # "branch max leaves"

MY_PWD="" # 'root' folder

H_FLAG="" # show hiden files (ls -A (-A = almost-all)) 
D_FLAG="" # show directories only
M_FLAG="" # show metadata

# find . -maxdepth 1 -regextype sed -regex "\(^\./PRE*\|.*IN.*\|.*END$\)"
REGEX=""  # regex used for ALL names (dirs or files)
PREGEX=""   # pre-regex     (starts)
INGEX=""    # in-regex      (contains)
POSTGEX=""  # post-regex    (ends)

##############################################################################
##############################################################################
##############################################################################
##############################################################################

# returns the icon to the corresponding file type*
# type*: based on the file name (myFile.txt -> text file...)
function icon()
{       
    case "$1" in
    *.txt)           echo  '󰈙' ;; # f0219
    *.zip)           echo  '' ;; # f1c6
    *.sh)            echo  '' ;; # e795
    *.py)            echo  '' ;; # e606
    *.c)             echo  '' ;; # e61e
    *.cpp)           echo  '' ;; # e61d
    *.h)             echo  '' ;; # eac4
    *.java)          echo  '' ;; # e256
    *.json)          echo  '' ;; # e60b
    *.html)          echo  '' ;; # e60e
    *.lua)           echo  '' ;; # e620
    *.png | *.jpeg)  echo  '󰈟' ;; # f021f
    *.pdf)           echo  '' ;; # eaeb
    *.mp3 | *.wav)   echo  '󰈣' ;; # f0223
    *.mp4)           echo  '󰈫' ;; # f022b
    .gitignore)      echo  '' ;; # e702
    Makefile)        echo  '' ;; # e673
    .*)              echo  '' ;; # ea7b
    *)               echo  '󰈔' ;; # f0214
    esac
}

# maps the icons
function get_icon()
{   
    declare MY_INPUT=${*:-$(</dev/stdin)}
    for PARAM in $MY_INPUT
    do        
        icon $PARAM
    done
}

# inserts the icon
function insert_icon()
{   
    declare MY_INPUT=${*:-$(</dev/stdin)}
    for INPUT in $MY_INPUT
    do
        printf "$(icon "${INPUT}") $(echo $INPUT | sed 's|//| |g')\n"
    done
}

# generates the tabs
function tabs() {
    printf "$T_BRIGHT"
    seq $1 | awk -v var="$C_LINE  " '{printf var}'
    printf "$T_RESET"
}

# counts the total number of element inside directory
function count_elements()
{
    cd "${1}"

    [[ -z $H_FLAG ]] && \
        echo $(find . -maxdepth 1 | grep -E "^\./[^\.].*" | wc -l) || \
        echo $(find . -maxdepth 1 | grep -E -v "^\.$" | wc -l) 
    
    cd ..
}

# looks inside directory and takes info about what is inside
function mine_info() 
{
    cd "${1}"
    
    printf "${T_BRIGHT}"

    # count number of files
    declare -i N_FILES=$([[ -z $H_FLAG ]] && \
        find . -maxdepth 1 -type f | grep -E -v "^\./\." | wc -l || \
        find . -maxdepth 1 -type f | wc -l
    )

    # count number of dirs
    declare -i N_DIRS=$([[ -z $H_FLAG ]] && \
        find . -maxdepth 1 -type d | grep -E "^\./\.?" | wc -l || \
        find . -maxdepth 1 -type d | grep -E "^\./[^\.]" | wc -l
    )
    
    # if none return
    [[ 0 -eq $N_DIRS && 0 -eq $N_FILES ]] && \
        printf "󰟢" && return 1
    
    [[ -z $M_FLAG ]] && \
        printf "$(($N_DIRS + $N_FILES)) elements" && return 1

    ## look for the file extentions
    EXTENTIONS=$([[ -z $H_FLAG ]] && \
                    find . -maxdepth 1 -type f | \
                        sed 's|^\./||g;/^\./d' | \
                        get_icon | \
                        LC_ALL=C sort | \
                        uniq | \
                        tr '\n' ',' | \
                        sed 's|,$||;' || \
                    find . -maxdepth 1 -type f | \
                        sed 's|^\./||g' | \
                        get_icon | \
                        LC_ALL=C sort | \
                        uniq | \
                        tr '\n' ',' | \
                        sed 's|,$||;' 
                    ) 
    # print all the info    
    [[ 0 -lt $N_DIRS ]] && \
        printf "d: $N_DIRS" && \
        [[ 0 -lt $N_FILES ]] && 
            printf ", " && \
            printf "f: $N_FILES ($EXTENTIONS)" && \
            return 1

    [[ 0 -lt $N_FILES ]] && \
        printf "f: $N_FILES ($EXTENTIONS)" 

    cd ..
}


function recursive()
{    
    declare -i ELEMENTS=0

    cd "$1"

    # DIRS
    for DIR in $([[ -z $H_FLAG ]] && \
        find . -maxdepth 1 -type d | \
            grep -E "\./[^\.].*" | \
            sort | \
            sed 's| |/|g'|| \
        find . -maxdepth 1 -type d | \
            grep -E -v "^\.$" | \
            sort | \
            sed 's| |/|g'
    )
    do 
        DIR=$(echo $DIR | sed 's|/| |g;s|\. |\./|')
        NAME="$(echo $DIR | sed 's|^\./||')"
        
        # print necesary tabulation
        tabs $2
        
        # count number of elements inside file
        ELEMENTS=$(count_elements "${DIR}")

        # check if has to many elements to show
        if [[ 0 -eq $ELEMENTS || $MAX_ELEMENTS -lt $ELEMENTS ]]; then
            [[ -z $(echo "$NAME" | grep "^\..") ]] && \
                printf "${T_RESET}$B_CLOSED_FOLDER $NAME  " || \
                printf "${T_BRIGHT}$H_CLOSED_FOLDER $NAME  "
        else
            [[ -z $(echo "$NAME" | grep "^\..") ]] && \
                printf "${T_RESET}$B_OPEN_FOLDER $NAME  " || \
                printf "${T_BRIGHT}$H_OPEN_FOLDER $NAME  "
        fi
       
        # print dir + info
        printf "${T_BRIGHT}$(mine_info "${DIR}")\n"

        # check if we have reached max_d or to many elements to show
        [[ $MAX_DEPTH -lt $2 || $MAX_ELEMENTS -lt $ELEMENTS || 0 -eq $ELEMENTS ]] && continue

        #echo -e "$T_UNDERLINED$T_BOLD\nDIR:$DIR\n$T_RESET" 
        # go inside directory and recursively repeat
        recursive "${DIR}" $(($2+1))
    done
        
    # FILES
    # check if only directory mode
    [[ -n $D_FLAG ]] && cd .. && return 1

    [[ 0 -eq $([[ -z $H_FLAG ]] && \
        find "." -maxdepth 1 -type f -regextype sed -regex "$REGEX" | grep -E -v "^\./\." | wc -l || \
        find "." -maxdepth 1 -type f -regextype sed -regex "$REGEX" | wc -l
    ) ]] && cd .. && return 1

    # print files
    printf  "$(
        [[ -z $H_FLAG ]] && \
          find "." -maxdepth 1 -type f -regextype sed -regex "$REGEX" | \
            sed 's|^./||g;/^\./d' | \
            sort | \
            sed 's| |/|g' | \
            insert_icon | \
            sed "s|^|$(tabs $2)|;s|/| |g" || \
          find "." -maxdepth 1 -type f -regextype sed -regex "$REGEX" | \
            sed 's|^./||g' | \
            sort | \
            sed "s|^\.|\\$T_BRIGHT\.|;s| |/|g" | \
            insert_icon | \
            sed "s|^|$(tabs $2)|;s|/| |g" 
            )\n"
    
    printf "$T_RESET"
        
    cd ..
    return 0
}

##############################################################################
##############################################################################
##############################################################################
##############################################################################

function help ()
{    
    echo -e "Usage: tree [-[amd]|-[xy] [0-9]+] [:path:] [:regex:]"
    echo -e "  e.g: tree -a 'show tree, with hiden folders'"
    echo -e "  e.g: tree -d -x 3 -m 'show tree, with only directories, MAX_DEPTH=3, show some metadata of directories'"
    echo -e "  e.g: tree -mad 'show tree, only directories, hiden directories and meta about them'"
    echo -e "Flags:"
    echo -e "  behaviour:"
    echo -e "    -a,\n      show hiden files/directories."
    echo -e "    -d,\n      hide files."
    echo -e "    -m --meta,\n      show more info about unopened folders."
    echo -e "    -p "...", --path "...",\n      set path."
    echo -e "    -r "...", --regex "...",\n      set regex for file matching. Regex tipe: 'sed'."
    echo -e "    -s "...", --startswith"...",\n      set estarting chars. No regex, just basic character comparation"
    echo -e "    -c "...", --contains"...",\n      check if fileName contains chars. No regex, just basic character comparation"
    echo -e "    -e "...", --endswith"...",\n      set ending chars. No regex, just basic character comparation"

    
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

function clean_gex() 
{
    echo "$@" | sed 's|\\|\\\\|g;s|\ |\\ |g;s|\.|\\.|g;s|\*|\\*|g;s|\^|\\^|g;s|\$|\\$|g'
}

function group_gexs()
{    
    [[ -z $PREGEX && -z $INGEX && -z $POSTGEX ]] && REGEX=".*";
    [[ -n $PREGEX ]] && PREGEX="^\./$(clean_gex $PREGEX).*";
    [[ -n $INGEX ]] && INGEX=".*$(clean_gex $INGEX).*";
    [[ -n $POSTGEX ]] && POSTGEX=".*$(clean_gex $POSTGEX)$";
    REGEX="\($REGEX\|$PREGEX\|$INGEX\|$POSTGEX\)"
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
        -p | --path) MY_PWD="$1"; shift;;
        -r | --regex) REGEX=$1; shift;;
        -s | --startswith) PREGEX=$1; shift;;
        -c | --contains) INGEX=$1; shift;;
        -e | --endswith) POSTGEX=$1; shift;;
        -*) concatenated_flags $ARG;; # echo "tree: error: unkown flag '$ARG', do 'tree -h' for help" && exit 0;;
        *) [[ -z $MY_PWD ]] && MY_PWD="$ARG" || [[ -z $REGEX ]] && REGEX=$ARG;;
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

# echo "pwd: $MY_PWD"
# echo "reg: $REGEX"
# echo "x:   $MAX_DEPTH"
# echo "y:   $MAX_ELEMENTS"

# echo "d: '$D_FLAG'"
# echo "h: '$H_FLAG'"
# echo "m: '$M_FLAG'"

# find "." -type f -regextype sed -regex "${REGEX}"

group_gexs

echo $REGEX

printf "$B_OPEN_FOLDER "
echo $MY_PWD | awk -F '/' '{print $NF}'

recursive "$MY_PWD" 1  
