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

set

IN_VCF=$1
DIR_TO_PARSE=$2

mkdir -p $DIR_TO_PARSE/MD5_REPORTS/

START_COMPRESS_VCF=`date '+%s'`

TABIX_EXEC=/isilon/sequencing/Kurt/Programs/TABIX/tabix-0.2.6/tabix
BGZIP_EXEC=/isilon/sequencing/Kurt/Programs/TABIX/tabix-0.2.6/bgzip

$BGZIP_EXEC -c $IN_VCF > $IN_VCF.gz && $TABIX_EXEC -h $IN_VCF.gz

rm -f $IN_VCF".idx"

END_COMPRESS_VCF=`date '+%s'`

echo $IN_VCF,COMPRESS_AND_INDEX_VCF,$START_COMPRESS_VCF,$END_COMPRESS_VCF \
>> $DIR_TO_PARSE/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv