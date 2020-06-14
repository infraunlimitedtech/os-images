#!/bin/bash

# FUNCTIONS #
show_help () {
    echo "\
        Usage: $0 <Options> command /path/to/iso_dir
        Commands:
            create - make iso
        Options:
            create:
            --var-file - path variables file. (for Centos)
            --additional-scripts
        "
        exit 0
}

cp_ks() {
  echo "Copying ks file into iso_dir..."
  install $ks_file $target_dir
  echo "Copying ks file into iso_dir...done"
}

cp_additional() {
  echo "Copying additional directory into iso_dir..."
  cp -a $additional_dir $target_dir
  echo "Copying additional directory into iso_dir...done"
}

read_vars() {
  echo "Take vars from ${var_file}"
  source ${var_file}
}

execute_scripts() {
  for s in ${scripts}; do
    eval $s "$target_dir/ks.cfg"
  done
}


mk_iso () {
  echo "Starting making new iso..."
  mkisofs -o ${output} -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -V "${label}" -boot-load-size 4 -boot-info-table -R -J -v -T "${target_dir}"
  echo "Making new iso...done"
}

main () {
read_vars
cp_ks
cp_additional
execute_scripts
mk_iso
}

# END FUNCTIONS #

if [ $# = 0 ]
then
  show_help
fi



TEMP=`getopt -o h,o: --long help:,var-file:,additional-scripts: -n 'parse-options' -- "$@"`
eval set -- "$TEMP"

while true 
do
  case $1 in 
    create ) 
      target_dir=$2
      main
      shift ;;
    --help ) 
      show_help
      shift ;;
    --var-file ) var_file=$2
      shift 2 ;;
    --additional-scripts ) scripts=$2
      shift 2 ;;
    --) shift ;;
    * ) 
      shift 
      break ;;
  esac
done
