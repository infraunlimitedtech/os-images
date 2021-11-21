#!/usr//bin/env bash


TARGET_DIR=${TARGET_DIR:=$(pwd)}
LABEL=${LABEL:=SOME_ISO}

iso=${1:?}
extra_dir=${2:?}

tmp_dir="${TARGET_DIR}/tmp"

# FUNCTIONS #
show_help () {
  echo "Usage: $0 /path/to/iso /path/to/dir"
  exit 0
}

prepare_iso() {
  echo "mount"
  mount $iso /mnt
  mkdir $tmp_dir
  cp -va /mnt/. $tmp_dir
}

cp_extra() {
  if [[ -f ${extra_dir}/hook.sh ]]; then cd $extra_dir; ./hook.sh && cd - ; fi
  echo "Copying extra dir into iso_dir..."
  cp -rva $extra_dir/. $tmp_dir
  echo "Copying extra dir into iso_dir...done"
}

mk_iso () {
  iso_name=$(basename ${iso} .iso)
  output="${TARGET_DIR}/${iso_name}-$(date +%s).iso"
  echo "Starting making new iso..."
  xorriso -as mkisofs -o ${output} -U -r -v -T -J -joliet-long -V ${LABEL} -volset ${LABEL} -A ${LABEL} -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot ${tmp_dir}
  echo "Making new iso...done"
}

clean() {
  rm -rfv $tmp_dir
  umount /mnt
}

main () {
  prepare_iso
  cp_extra
  mk_iso
  clean
}

# END FUNCTIONS #

if [ $# = 0 ]; then show_help; fi

main

