#!/bin/bash

#  script to modify CCCP server generated PDB bundle templates
#
# Usage example:
#   $ bash modify_cccp_bundles.sh -p "/full/path/to/CCCP" -r 28
#
# Author:  James Thornton
# Version: 1.0.1
# License: MIT


set -u -e -o pipefail


# optional arguments
_VERBOSE=0         # verbosity level, 0 for output to terminal, 1 for silent
seg_id="A"         # segment ID
chains='A B C D'   # chains existing in the CCCP bundles
chain_id="A"       # chain ID to change the other chains to
cccp_sep="poly-"   # CCCP server creates folders with poly-ala, can rename dirs
residues='ala gly' # residue names (currently only supports 'ala' and 'gly'

# required arguments
res_per_chain=""        # residues per chain, positive non-zero integer
path_to_cccp_bundles="" # path to the dir containing the CCCP generated bundles


OPTIND=1

usage="$(basename "$0") [-h] [-arguments]

Modify CCCP generated server bundles.

arguments:

  -p  full path to CCCP bundle directory (mandatory: str)
  -r  residues per chain (mandatory: int)
  -s  set segment ID to value (default: 'A')
  -z  chains list (default: 'A B C D')
  -c  set all chain IDs to value (default: 'A')
  -e  dir separator in CCCP dir i.e. poly-, poly_ (default: 'poly-')
  -a  residue names list (default: 'ala gly')
  -v  output logging to screen, must be either 0 for output (default) or 1
  -h  show this help message
  "

if [[ ${#} -eq 0 ]]; then
  echo "$usage"
  exit 1
fi

while getopts ':hs:z:c:e:a:p:r:v:' option;
do
  case "$option" in
    h)
      echo "$usage"
      exit 1
      ;;
    s)
      seg_id="$OPTARG"
      ;;
    z)
      chains="$OPTARG"
      ;;
    c)
      chain_id="$OPTARG"
      ;;
    e)
      cccp_sep="$OPTARG"
      ;;
    a)
      residues="$OPTARG"
      ;;
    p)
      path_to_cccp_bundles="$OPTARG"
      ;;
    r)
      res_per_chain=$OPTARG
      ;;
    v)
      _VERBOSE=$OPTARG
      ;;
    :)
      printf "missing argument for -%s\n" "$OPTARG" >&2
      echo "$usage" >&2
      exit 1
      ;;
    \?)
      printf "illegal option: -%s\n" "$OPTARG" >&2
      echo "$usage" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "$res_per_chain" ]; then
  echo "-r res_per_chain is mandatory: must be integer greater than 1"
  echo "$usage" >&2
  exit 1
fi

if [ -z "$path_to_cccp_bundles" ]; then
  echo "-r path_to_cccp_bundles is mandatory"
  echo "$usage" >&2
  exit 1
fi

if [ "$res_per_chain" -le 0 ]; then
  echo "-r res_per_chain is mandatory: must be integer greater than 1"
  echo "$usage" >&2
  exit 1
fi

if [ "$_VERBOSE" != 0 ] && [ "$_VERBOSE" != 1 ]; then
  echo "-v _VERBOSE must be either 0 for outputting messages or 1 for silent"
  echo "$usage" >&2
  exit 1
fi

readonly seg_id chains chain_id cccp_sep residues path_to_cccp_bundles \
         res_per_chain _VERBOSE


tmpfile="$(mktemp)"
tmpphnx=phenix.out


log () {
  if [[ $_VERBOSE -eq 0 ]]; then
    echo "$@"
  fi
}

mkdir_and_cd () {
  mkdir -p "$1"; cd "$1"
}

res_one_letter_cap () {
  local abbrev && abbrev=$(printf %.1s "$1")
  Abbrev="${abbrev^}"
  echo "$Abbrev"
}

#  write Rosetta residue file for all Ala or Gly
write_resfiles () {
  local res_abbrev && res_abbrev=$(res_one_letter_cap "$1")
  local file_name && file_name="all_${1}_resfile.res"
  rm -f "$file_name" # appends if exists)
  printf $"PIKAA %s\nstart" "$res_abbrev" >> "$file_name"
  log "@>> finished writing $1 resfile"
}

#  execute Rosetta fix backbone to add side chains and hydrogen's
exe_Rosetta_fixbb () {
  local fullpdbpath && fullpdbpath="$path_to_cccp_bundles"/"$cccp_sep${1}"/
  local numfiles && numfiles=$(find "$fullpdbpath" | wc -l)
  local i && i=0
  SECONDS=0
  for pdb in "$fullpdbpath"*.pdb;
  do
    ((i++))
    filename="${pdb##*/}"
    log "@>> starting Rosetta fixbb for $filename ($i/$(( numfiles - 1 )))"
    fixbb.default.linuxgccrelease -s "$pdb" -resfile \
    ../all_"${1}"_resfile.res -nstruct 1 -ex1 -ex2 -database \
    "$ROSETTA3_DB" > /dev/null
    log "@>> finished Rosetta fixbb for $filename"
  done
  DURATION=$SECONDS
  log "@>> Rosetta fixbb for $1 finished in ~$DURATION seconds"
}

run_Rosetta_fixbb () {
  mkdir_and_cd ./poly_"${1}" && exe_Rosetta_fixbb "$1" && \
    rm score.sc && cd ../ || exit
}

rename_pdbs () {
  log "@>> renaming ${1} pdbs"
  f=0
  for pdb in ./poly_"${1}"/*.pdb;
  do
    ((++f)) # increment first or it doesn't work
    ext="${pdb##*.}"
    printf -v j "%04d" "$f"
    filename="${1}_${j}"
    mv "$pdb" ./poly_"${1}"/"${filename}"."$ext" # need to include rel path
    log "@>> finished renaming ${pdb} to ${filename}.${ext}"
  done
  log "@>> finished renaming ${1} pdbs"
}

mod_segment_ter_chain_id () {
  log "@>> removing TER lines"
  sed -i "/TER/d" $tmpphnx
  log "@>> changing chains to $chain_id"
  awk '{print substr($0,1,21) v substr($0,23)}' v="$chain_id" $tmpphnx \
    > "$tmpfile" && mv "$tmpfile" $tmpphnx
  log "@>> changing segment IDs to $seg_id"
  awk '{print substr($0,1,75) v substr($0,76)}' v="$seg_id" $tmpphnx \
    > "$tmpfile" && mv "$tmpfile" $tmpphnx
}

chain_resseq_mod () {
  phenix.pdbtools "$1" clear_seg_id=true \
    output.filename=$tmpphnx > /dev/null
  read -ra chain_ar <<<"$chains" && len_chains=${#chain_ar[@]} && i=1 || exit
  while [ $i -le $((len_chains - 1)) ];
  do
    log "@>> modifying sequence for chain ${chain_ar[$i]}"
    inc_resseq=$((i * res_per_chain))
    phenix.pdbtools $tmpphnx modify.selection="chain ${chain_ar[$i]}" \
      increment_resseq=$inc_resseq output.filename=$tmpphnx > /dev/null
    ((i++))
  done
}

run_phenix () {
  mkdir_and_cd ../phenix/
  for file in ../Rosetta/poly_"${res}"/*.pdb;
  do
    mkdir -p ../templates/poly_"${res}"
    filename="${file##*/}"
    cp "$file" "$filename"
    log "@>> modifying sequence IDs for $filename"
    chain_resseq_mod "$filename"
    log "@>> modifying chain IDs, segments and removing ter for $filename"
    mod_segment_ter_chain_id
    log "@>> finished $filename"
    mv $tmpphnx ../templates/poly_"${res}"/"$filename"
    rm "$filename"
  done
}

main () {
  local date && date=$(date '+%Y-%m-%d %H:%M:%S')
  local kernal_v && kernal_v=$(uname -a)
  log ""
  log "${date}"
  log "${kernal_v}"
  log "Bash version ${BASH_VERSINFO[*]}"
  log ""
  log "@>> Starting CCCP bundle modifications"

  mkdir_and_cd ./Rosetta
  for res in $residues;
  do
    log "@>> writing resfile for $res"
    write_resfiles "$res"
    log "@>> starting Rosetta fixed backbone for $res"
    run_Rosetta_fixbb "$res"
    log "@>> starting renaming PDBs for $res"
    rename_pdbs "$res"
    log "@>> starting phenix modifications for $res"
    run_phenix "$res"
    log "@>> finished all modifications for $res"
    cd ../Rosetta
  done
  cd ../ && rm -rf ./{phenix,Rosetta}
  log "@>> Finished CCCP bundle modifications"
}

main "$@"
