# tree

Outputs the directories, subdirectories, and files as a tree.

---

## use

**Usage:** tree \[-\[amd\]|-\[xy\] \[0-9\]+\] \[-p dir\] \[-rsc regex\]
+ e.g: tree -a 'show tree, with hiden folders'
+ e.g: tree -d -x 3 -m 'show tree, with only directories, MAX_DEPTH=3, show some metadata of directories'
+ e.g: tree -mad 'show tree, only directories, hiden directories and meta about them'
+ e.g: tree -c \"app\" -e \".txt\" -e \".c\" 'show tree, with files that (c)ontain \"app\" or (e)nd with \".txt\" or \".c\"'

**Flags:**

**behaviour:**
+ -a,
    + show hiden files/directories
+ -d,
    + hide files
+ -m --meta,
    + show more info about unopened folders
+ -p "...", --path "...",
    + set path"

**regex:**
+ -r "...", --regex "...",    
    + set regex for file matching. Regex tipe: 'sed'
+ -s "...", --startswith"...",
    + set estarting chars. No regex, just basic character comparation
+ -c "...", --contains"...",
    + check if fileName contains chars. No regex, just basic character comparation
+ -e "...", --endswith"...",\n      
    + set ending chars. No regex, just basic character comparation

**distance:**
+ -x #, --depth #
    + goes # directories depth. default = 8.
+ -y #, --elements #
    + shows file contents if it has less than # number of elements. default = 16.

## img

<img title="tree -mad" alt="img" src="/img/tree_a.png">
<img title="tree -mad" alt="img" src="/img/tree_mad.png">

## tools

- [nerdfonts](https://www.nerdfonts.com/#home)
- [ASCII-table](https://ascii-tables.com/)


