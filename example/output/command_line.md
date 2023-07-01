(base) username@username-Aspire-A315-51:~/Desktop/template_mods$ source ~/set_Phenix.sh
(base) username@username-Aspire-A315-51:~/Desktop/template_mods$ source ~/set_Rosetta.sh
(base) username@username-Aspire-A315-51:~/Desktop/template_mods$ bash modify_cccp_bundles.sh
modify_cccp_bundles.sh [-h] [-s A] [-z 'A B'] [-c A] [-e 'poly-'] [-a 'ala gly'] -p PATH -r INT

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

(base) username@username-Aspire-A315-51:~/Desktop/template_mods$ bash modify_cccp_bundles.sh -p "/home/username/Desktop/CCCP" -r 28 -s A -z 'A B C D' -c A -e 'poly-' -a 'ala gly' -v 0

2023-07-01 09:26:54
Linux username-Aspire-A315-51 5.15.0-76-generic #83-Ubuntu SMP Thu Jun 15 19:16:32 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
Bash version 5 1 16 1 release x86_64-pc-linux-gnu

@>> --- Starting CCCP bundle modifications
@>> writing resfile for ala
@>> finished writing ala resfile
@>> starting rosetta fixed backbone for ala
@>> starting rosetta fixbb for 00001.396f8ee2d646.allbb_ala.pdb (1/2)
@>> finished rosetta fixbb for 00001.396f8ee2d646.allbb_ala.pdb
@>> starting rosetta fixbb for 00002.396f8ee2d646.allbb_ala.pdb (2/2)
@>> finished rosetta fixbb for 00002.396f8ee2d646.allbb_ala.pdb
@>> rosetta fixbb for ala finished in ~14 seconds
@>> starting renaming PDBs for ala
@>> renaming ala pdbs
@>> finished renaming ./poly_ala/00001.396f8ee2d646.allbb_ala_0001.pdb to ala_0001.pdb
@>> finished renaming ./poly_ala/00002.396f8ee2d646.allbb_ala_0001.pdb to ala_0002.pdb
@>> finished renaming ala pdbs
@>> starting phenix modifications for ala
@>> clearing segment ID for ala_0001.pdb
@>> modifying sequence IDs for ala_0001.pdb
@>> modifying sequence for chain B
@>> modifying sequence for chain C
@>> modifying sequence for chain D
@>> modifying chain IDs, segments and removing ter for ala_0001.pdb
@>> removing TER lines
@>> changing chains to A
@>> changing segment IDs to A
@>> finished ala_0001.pdb
@>> clearing segment ID for ala_0002.pdb
@>> modifying sequence IDs for ala_0002.pdb
@>> modifying sequence for chain B
@>> modifying sequence for chain C
@>> modifying sequence for chain D
@>> modifying chain IDs, segments and removing ter for ala_0002.pdb
@>> removing TER lines
@>> changing chains to A
@>> changing segment IDs to A
@>> finished ala_0002.pdb
@>> finished all modifications for ala
@>> writing resfile for gly
@>> finished writing gly resfile
@>> starting rosetta fixed backbone for gly
@>> starting rosetta fixbb for 00001.396f8ee2d646.allbb.pdb (1/2)
@>> finished rosetta fixbb for 00001.396f8ee2d646.allbb.pdb
@>> starting rosetta fixbb for 00002.396f8ee2d646.allbb.pdb (2/2)
@>> finished rosetta fixbb for 00002.396f8ee2d646.allbb.pdb
@>> rosetta fixbb for gly finished in ~13 seconds
@>> starting renaming PDBs for gly
@>> renaming gly pdbs
@>> finished renaming ./poly_gly/00001.396f8ee2d646.allbb_0001.pdb to gly_0001.pdb
@>> finished renaming ./poly_gly/00002.396f8ee2d646.allbb_0001.pdb to gly_0002.pdb
@>> finished renaming gly pdbs
@>> starting phenix modifications for gly
@>> clearing segment ID for gly_0001.pdb
@>> modifying sequence IDs for gly_0001.pdb
@>> modifying sequence for chain B
@>> modifying sequence for chain C
@>> modifying sequence for chain D
@>> modifying chain IDs, segments and removing ter for gly_0001.pdb
@>> removing TER lines
@>> changing chains to A
@>> changing segment IDs to A
@>> finished gly_0001.pdb
@>> clearing segment ID for gly_0002.pdb
@>> modifying sequence IDs for gly_0002.pdb
@>> modifying sequence for chain B
@>> modifying sequence for chain C
@>> modifying sequence for chain D
@>> modifying chain IDs, segments and removing ter for gly_0002.pdb
@>> removing TER lines
@>> changing chains to A
@>> changing segment IDs to A
@>> finished gly_0002.pdb
@>> finished all modifications for gly
@>> --- Finished CCCP bundle modifications

(base) username@username-Aspire-A315-51:~/Desktop/template_mods$
