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

	IN_BAM=$1
		SM_TAG=$(basename $IN_BAM .bam)
	DIR_TO_PARSE=$2
	COUNTER=$3
	JAVA_1_7=$4
	PICARD_DIR=$5

START_BAM_VALIDATION=`date '+%s'`

	$JAVA_1_7/java -jar $PICARD_DIR/picard.jar \
		ValidateSamFile \
		INPUT= $IN_BAM \
		MODE=SUMMARY \
	OUTPUT= $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG"_bam."$COUNTER".txt"

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

END_BAM_VALIDATION=`date '+%s'`

echo $IN_BAM,CRAM,$BAM_FILE_SIZE,$CRAM_FILE_SIZE,$HOSTNAME,$START_CRAM,$END_CRAM \
>> $DIR_TO_PARSE/cram_compression_times.csv

# exit with the signal from the program

	exit $SCRIPT_STATUS
