# tree

Outputs the directories, subdirectories, and files as a tree.

---

## use

**Usage:** tree [-[amd]|-[xy] [0-9]+] [dir]
    + e.g: tree -a 'show tree, with hiden folders'
    + e.g: tree -d -x 3 -m 'show tree, with only directories, MAX_DEPTH=3, show some metadata of directories'
    + e.g: tree -mad 'show tree, only directories, hiden directories and meta about them'
**Flags:**
**behaviour:**
+ -a,
    + show hiden files/directories.
+ -d,
    + hide files.
+ -m --meta,
    + show more info about unopened folders.
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


