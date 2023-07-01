# paths to Rosetta executables, the database and a gcc dir that was causing
# issues on my system - LD_LIBRARY_PATH may not be needed on other systems

export PATH=/usr/local/rosetta.source.release-340/main/source/bin:$PATH
export ROSETTA3_DB=/usr/local/rosetta.source.release-340/main/database/
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/rosetta.source.release-340/main/source/build/external/release/linux/5.15/64/x86/gcc/11/default:$LD_LIBRARY_PATH
