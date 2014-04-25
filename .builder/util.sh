#!/bin/bash
# $Id$
# shell utility for builder

# usage
#   util_cp <dest> <src...> <ex>
# option
#   dest  destination directory
#   src   source directory
#   ex    exclude file/directory name pattern
# description
#   copy recursive from source directory to destination directory and 
#   bypass any file or directory name to exclude
# example
#   util_cp "./runtime" "$dir1 $dir2" ".svn .ld .la .a" 
#     copy $dir1 and $dir2 directory to ./runtime
#     ignore any file or directory name in .svn, *.ld, *.la or *.a

util_cp() {


}
