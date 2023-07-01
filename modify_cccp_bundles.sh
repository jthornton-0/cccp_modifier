#!/bin/bash

# --- bash script to modify CCCP server generated PDB bundle templates
#
# CCCP generated poly-glycine and poly-alanine PDBs need to be modified before
# they can be used, namely their segment IDs match their chain IDs (i.e. in
# PyMOL it is /A/A, /B/B etc), each chain is numbered from 1 and the poly-ala
# chains do not posses the side chains. Whilst this is the stated aim of the
# CCCP server for which we are grateful, this script modifies them to a point
# where they can be used for further design.
#
# The segment IDs can be changed to all of the same through segID, multiple
# chains are supported (in the form of 'A B ... X Y Z', chain IDs are changed
# to all of the same through chainID and the residues per chain are incremented
# so that they are continuous (for example, if all chains are 28 residues long,
# then chain A is untouched and chain B will start from 29 instead of 1, chain
# C from 57 etc). The path to the CCCP generated bundles must be the full path.
#
# The paths to the Rosetta /bin/, Rosetta /database/ and phenix /bin/ must be
# set before running the script.
#
# The CCCP server pads their files i.e. 00001, 00002...file.pdb so order is
# guaranteed with the original PDBs.
#
# TODO: add support for allowing the templates to be used to make poly-val or
#       other residues, currently breaks if 'residues' is not 'gly ala'
#
# If there are any issues, please post an issue or pull request.
#
# Usage example:
#   $ bash modify_cccp_bundles.sh -p "/full/path/to/CCCP" -r 28
#
# Author:  James Thornton
# Version: 1.0
# License: MIT
#
# References
# ----------
# CCCP:    https://www.grigoryanlab.org/cccp/
# Phenix:  https://phenix-online.org/documentation/index.html
# Rosetta: https://www.rosettacommons.org/

# -------------------------------------------------------------------  SETTINGS

set -u -e -o pipefail

# -------------------------------------------------------------------  DEFAULTS

# default options
segID="A"          # segment ID
chains='A B C D'   # chains existing in the CCCP bundles
chainID="A"        # chain ID to change the other chains to
cccp_sep="poly-"   # CCCP server creates folders with poly-ala, can rename dirs
residues='ala gly' # residue names
_VERBOSE=0
res_per_chain=""
path_to_cccp_bundles=""


# -------------------------------------------------------------------  CMD LINE

OPTIND=1 # reset

usage="$(basename "$0") [-h] [-s A] [-z 'A B'] [-c A] [-e 'poly-'] [-a 'ala gly'] -p PATH -r INT

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
    h) echo "$usage"
       exit 1
       ;;
    s) segID="$OPTARG"
       ;;
    z) chains="$OPTARG"
       ;;
    c) chainID="$OPTARG"
       ;;
    e) cccp_sep="$OPTARG"
       ;;
    a) residues="$OPTARG"
       ;;
    p) path_to_cccp_bundles="$OPTARG"
       ;;
    r) res_per_chain=$OPTARG
       ;;
    v) _VERBOSE=$OPTARG
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
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

# ------------------------------------------------------------------- CONSTANTS

# --- temp files
tmpfile="$(mktemp)"
phnxtmp=phenix.out

# -------------------------------------------------------------------  LOG

# --- log function for verbose mode output
log () {
    if [[ $_VERBOSE -eq 0 ]]; then
        echo "$@"
    fi
}

# ------------------------------------------------------------------- FUNCTIONS

# --- extract first character from string and return capitalised
res_one_letter_cap () {
    abbrev=$(printf %.1s "$1")
    Abbrev="${abbrev^}"
    echo "$Abbrev"
}

# --- write Rosetta residue file for all Ala or Gly
write_resfiles () {
    res_abbrev=$(res_one_letter_cap "$1")
    file_name="all_${1}_resfile.res"
    rm -f "$file_name" # appends if exists)
    echo -e $"PIKAA ${res_abbrev}\nstart" >> "$file_name"
    log "@>> finished writing $1 resfile"
}

# --- execute Rosetta fix backbone to add side chains and hydrogen's
exe_Rosetta_fixbb () {
    fullpdbpath="$path_to_cccp_bundles"/"$cccp_sep${1}"/
    numfiles=$(find "$fullpdbpath" | wc -l)
    i=0
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

# --- run Rosetta fixed backbone scripts
run_Rosetta_fixbb () {
    create_and_cd ./poly_"${1}" && exe_Rosetta_fixbb "$1" && \
        rm score.sc && cd ../ || exit
}

# --- rename the Rosetta output PDBs to more readable ones in the form
# --- 'ala_0001.pdb', 'gly_0064' etc
rename_pdbs () {
    log "@>> renaming ${1} pdbs"
    f=0
    for pdb in ./poly_"${1}"/*.pdb;
    do
        ((++f)) # increment first or it doesn't work
        ext="${pdb##*.}"
        printf -v j "%04d" "$f" # pad the int to 4 d.p. i.e. 12 -> 0012
        filename="${1}_${j}"
        mv "$pdb" ./poly_"${1}"/"${filename}"."$ext" # need to include rel path
        log "@>> finished renaming ${pdb} to ${filename}.${ext}"
    done
    log "@>> finished renaming ${1} pdbs"
}

# --- remove TER lines so chains are continuous, change all chains to 'A' or
# --- user input value and set segment ID to 'A' or user value
mod_segment_ter_chainid () {
    # remove TER lines
    log "@>> removing TER lines"
    sed -i "/TER/d" $phnxtmp
    # change chain to A
    log "@>> changing chains to $chainID"
    awk '{print substr($0,1,21) v substr($0,23)}' v="$chainID" $phnxtmp\
        > "$tmpfile" && mv "$tmpfile" $phnxtmp
    # to add $segID as segment
    log "@>> changing segment IDs to $segID"
    awk '{print substr($0,1,75) v substr($0,76)}' v="$segID" $phnxtmp \
        > "$tmpfile" && mv "$tmpfile" $phnxtmp
}

# --- increment the residue sequences of chains that are not A so that they
# --- can be merged into one chain with discontinuities
chain_resseq_mod () {
    read -ra chain_ar <<<"$chains" && len_chains=${#chain_ar[@]} && i=1 || exit
    while [ $i -le $((len_chains - 1)) ];
    do
        log "@>> modifying sequence for chain ${chain_ar[$i]}"
        inc_resseq=$((i * res_per_chain))
        phenix.pdbtools $phnxtmp modify.selection="chain ${chain_ar[$i]}" \
            increment_resseq=$inc_resseq output.filename=$phnxtmp > /dev/null
        ((i++))
    done
}

# --- clear the segment IDs (set as chain ID by default with the CCCP server)
# --- so that they can be easily set later on, this may be redundant TODO
clear_segid () {
    phenix.pdbtools "$1" clear_seg_id=true \
        output.filename=$phnxtmp > /dev/null
}

# --- main function to run phenix operations
run_phenix () {
    create_and_cd ../phenix/
    for file in ../Rosetta/poly_"${res}"/*.pdb;
    do
        mkdir -p ../templates/poly_"${res}"
        filename="${file##*/}"
        cp "$file" "$filename"
        log "@>> clearing segment ID for $filename"
        clear_segid "$filename"
        log "@>> modifying sequence IDs for $filename"
        chain_resseq_mod
        log "@>> modifying chain IDs, segments and removing ter for $filename"
        mod_segment_ter_chainid
        log "@>> finished $filename"
        mv $phnxtmp ../templates/poly_"${res}"/"$filename"
        rm "$filename"
    done
}

# --- create directory and change to it
create_and_cd () {
    mkdir -p "$1"; cd "$1"
}

# -------------------------------------------------------------------      MAIN


# --- output system information to the terminal, if unwanted then comment out
date=$(date '+%Y-%m-%d %H:%M:%S')
kernal_v=$(uname -a)

log ""
log "${date}"
log "${kernal_v}"
log "Bash version ${BASH_VERSINFO[*]}"
log ""
log "@>> --- Starting CCCP bundle modifications"


# --- main loop
create_and_cd ./Rosetta

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

# --- remove the working folders
cd ../ && rm -rf ./{phenix,Rosetta}

log "@>> --- Finished CCCP bundle modifications"
log ""
