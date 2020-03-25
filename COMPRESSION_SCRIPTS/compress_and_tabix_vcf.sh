# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge that you are in the users current working directory
#$ -cwd

# tell sge to export the users environment variables
#$ -V

# tell sge to submit at this priority setting
#$ -p -1020

# tell sge to output both stderr and stdout to the same file
#$ -j y

# export all variables, useful to find out what compute node the program was executed on

	set

	echo

# INPUT VARIABLES

	IN_VCF=$1
	DIR_TO_PARSE=$2
	TABIX_EXEC=$3
	BGZIP_EXEC=$4

START_COMPRESS_VCF=`date '+%s'`

	# if any part of pipe fails set exit to non-zero

		set -o pipefail

	# compress vcf with bgzip and create tbi index

		$BGZIP_EXEC -c $IN_VCF > $IN_VCF.gz && $TABIX_EXEC -h $IN_VCF.gz

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# delete the tribble index

		rm -f $IN_VCF".idx"

END_COMPRESS_VCF=`date '+%s'`

echo $IN_VCF,COMPRESS_AND_INDEX_VCF,$HOSTNAME,$START_COMPRESS_VCF,$END_COMPRESS_VCF \
>> $DIR_TO_PARSE/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit $SCRIPT_STATUS
