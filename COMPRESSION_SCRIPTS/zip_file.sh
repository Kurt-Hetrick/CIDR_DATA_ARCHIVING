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

IN_FILE=$1
DIR_TO_PARSE=$2

mkdir -p $DIR_TO_PARSE/TEMP/

START_ZIP=`date '+%s'`

gzip -f -c $IN_FILE >| $IN_FILE.gz 

END_ZIP=`date '+%s'`

 echo $IN_FILE,ZIP,$START_ZIP,$END_ZIP \
 >> $DIR_TO_PARSE/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv