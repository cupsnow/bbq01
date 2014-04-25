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
#   util_cp "./runtime" "$dir1 $dir2/*" ".svn .ld .la .a" 
#     copy $dir1 and $dir2 directory to ./runtime
#     ignore any file or directory name in .svn, *.ld, *.la or *.a

util_cp() {
  DEST=$1
  SRC=$2
  EX=$3
  
  let SRC_CNT=0
  for SRC1 in $SRC ; do
    let SRC_CNT=$SRC_CNT + 1
  done
  
  if [ "$SRC_CNT" -lt 1 ] ; then
    return 0
  elif [ "$SRC_CNT" -gt 1 ] ; then
    for SRC1 in "$SRC" ; do
      util_cp
    done
    return 0
  fi
  
  
  
    
}
