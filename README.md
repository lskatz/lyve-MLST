lyve-MLST
=========

A module for typing whole genomes, given a BigsDB-style MLST database.

INSTALLATION
======

Configure the first several lines of the module by setting the variables listed.  Some variables are SGE variables but will be ignored if you do not use 'qsub.'  

Place this script in your path

    export PATH=$PATH:/path/to/lyve-MLST

USAGE
======

Create a project directory

    mkdir -p projectDirectory/{assemblies,blast,db}

Add all genome assemblies you wish to type into the assemblies directory.  They must have .fasta extensions.  The blast directory will have temporary blast output files that you can delete.  However these blast temporary files will save on cpu if you re-run this script.  The db directory will have the downloaded MLST scheme which is are also technically temporary files.  The scheme will not be updated between runs unless you delete those files.  In other words, the script will not re-download any scheme that is present.

Then, run by executing

    mlst.sh > mlstprofiles.sh

or the SGE way

    qsub -o mlstprofiles.tsv `which mlst.sh`

OUTPUT
======

The output is a tab-separated-values (tsv) file with the following fields:

    assemblyName  locus1  locus2 ... locusX  combinedBlastScore

Those with a lower combined blast score do not have 100% identity and coverage and should be examined more closely.  The maximum combined score is hopefully obvious from the majority of your results and will vary with each MLST scheme.  At this time the ST column is not present; hopefully it can be filled in, with a future version of the script.
