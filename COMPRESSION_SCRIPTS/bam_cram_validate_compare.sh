# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge to submit any of these queue when available
#$ -q rnd.q,prod.q,test.q

# tell sge that you are in the users current working directory
#$ -cwd

# tell sge to export the users environment variables
#$ -V

# tell sge to submit at this priority setting
#$ -p -1020

# tell sge to output both stderr and stdout to the same file
#$ -j y

# export all variables, useful to find out what compute node the program was executed on
# redirecting stderr/stdout to file as a log.

IN_BAM=$1
MAIN_DIR=$2
COUNTER=$3

BAM_DIR=$(dirname $IN_BAM)
BAM_MAIN_DIR=$(echo $BAM_DIR | sed -r 's/BAM.*//g')
CRAM_DIR=$(echo $IN_BAM | sed -r 's/BAM.*/CRAM/g')
SM_TAG=$(basename $IN_BAM .bam) 
DATAMASH_EXE=/isilon/sequencing/Kurt/Programs/PATH/datamash
SAMTOOLS_EXE=/isilon/sequencing/Kurt/Programs/samtools/samtools-1.6/samtools

# Made this explicit if the validation output files are not found it will fail
# this does not account for if the file is empty.

# if [[ -e $MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram."$COUNTER".txt" && -e $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG"_bam."$COUNTER".txt" ]]
# 	then
# 		CRAM_ONLY_ERRORS=$(grep -F -x -v -f $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG"_bam."$COUNTER".txt" $MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram."$COUNTER".txt" | grep -v "No errors found")
# 	else
# 		CRAM_ONLY_ERRORS=$(echo FAILED_CONVERSION)
# fi

if [[ -e $MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram."$COUNTER".txt" && \
-e $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG"_bam."$COUNTER".txt" && \
-s $MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram."$COUNTER".txt" && \
-s $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG"_bam."$COUNTER".txt" ]]
	then
		CRAM_ONLY_ERRORS=$(grep -F -x -v -f $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG"_bam."$COUNTER".txt" \
		$MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram."$COUNTER".txt" \
		| grep -v "No errors found")
	else
		CRAM_ONLY_ERRORS=$(echo FAILED_CONVERSION_OR_VALIDATION)
fi

## Create two temp files for the output of flagstat for bam and cram file.
## If the two files are the same AND the CRAM_ONLY_ERRORS variable is null will the output verify the conversion was sucessful.
## If either of these fail, the error file will show this.  

$SAMTOOLS_EXE flagstat $BAM_DIR/$SM_TAG.bam >| $MAIN_DIR/TEMP/$SM_TAG".bam."$COUNTER".flagstat.out"
$SAMTOOLS_EXE flagstat $CRAM_DIR/$SM_TAG.cram >| $MAIN_DIR/TEMP/$SM_TAG".cram."$COUNTER".flagstat.out"

if [[ ! -e $MAIN_DIR/cram_conversion_validation.list ]]
	then
	echo -e SAMPLE\\tCRAM_CONVERSION_SUCCESS\\tCRAM_ONLY_ERRORS\\tNUMBER_OF_CRAM_ONLY_ERRORS >| $MAIN_DIR/cram_conversion_validation.list
fi

if [[ -z $(diff $MAIN_DIR/TEMP/$SM_TAG".bam."$COUNTER".flagstat.out" $MAIN_DIR/TEMP/$SM_TAG".cram."$COUNTER".flagstat.out" ) && -z $CRAM_ONLY_ERRORS ]]
	then
 		echo $SM_TAG CRAM COMPRESSION WAS COMPLETED SUCCESSFULLY
		echo -e $IN_BAM\\tPASS\\t$CRAM_ONLY_ERRORS | sed -r 's/[[:space:]]+/\t/g' >> $MAIN_DIR/cram_conversion_validation.list
		# Put this back in after debugging.
		rm -vf $BAM_DIR/$SM_TAG.bam
		rm -vf $BAM_DIR/$SM_TAG.bai
	else
 		echo $SM_TAG CRAM COMPRESSION WAS UNSUCCESSFUL
		(echo BAM; cat $MAIN_DIR/TEMP/$SM_TAG".bam."$COUNTER".flagstat.out"; echo -e \\nCRAM; cat $MAIN_DIR/TEMP/$SM_TAG".cram."$COUNTER".flagstat.out") >| $MAIN_DIR/TEMP/$SM_TAG".combined."$COUNTER".flagstat.out"
		echo -e $IN_BAM\\tFAIL\\t$CRAM_ONLY_ERRORS | sed -r 's/[[:space:]]+/\t/g' >> $MAIN_DIR/cram_conversion_validation.list
# 		mail -s "$IN_BAM Failed Cram conversion-Cram Flagstat Output" vcaropr1@jhmi.edu < $MAIN_DIR/TEMP/$SM_TAG".combined."$COUNTER".flagstat.out"
fi

# Put back in after debugging

# Remove own directory once it hits zero, but if it's in the AGGREGATE folder.... Only removes that one and not the complete BAM
if [[ $(find $BAM_DIR -type f | wc -l) == 0 ]]
	then
		rm -rvf $BAM_DIR
fi

if [[ -e $MAIN_DIR/BAM && $(find $MAIN_DIR/BAM -type f | wc -l) == 0 ]]
	then
		rm -rvf $MAIN_DIR/BAM
fi


 echo $CRAM_DIR/$SM_TAG".cram",BAM_CRAM_VALIDATION_COMPARE,$START_CRAM_VALIDATION,$END_CRAM_VALIDATION \
 >> $MAIN_DIR/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv

##Something to work on/think about.... Output to e-mail being side by side
#	paste  $MAIN_DIR/TEMP/$SM_TAG".bam.flagstat.out" $MAIN_DIR/TEMP/$SM_TAG".cram.flagstat.out" | awk 'BEGIN {FS="\t" ; print "BAM""\t""CRAM"} { printf "%-100s %s\n", $1, $2 }' >| $MAIN_DIR/TEMP/$SM_TAG".combined.flagstat.out"
