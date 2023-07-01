# cccp_modifier dependencies

For the function of the script, the [Rosetta software suite][1] and [phenix][2]
tools are required to be available on the system. Whilst there could be a
workaround for phenix tools as it is just needed to renumber the residues
(PyMOL can do the same), Rosetta is essential due to adding methyl sidechains
to the poly-alanine bundles.

## Files to source

The files containing paths to the relevant executables and databases must be
sourced before running the script. The source files used to generate the output
are contained within the above folders.

[1]: https://www.rosettacommons.org/software
[2]: https://phenix-online.org/
