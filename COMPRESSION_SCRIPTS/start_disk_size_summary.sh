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

	INPUT_DIRECTORY=$1 # path to directory that you want to check file sizes on.
		INPUT_DIR_NAME=$(basename $INPUT_DIRECTORY)
	ROW_COUNT=$2
	TIME_STAMP=$3
	DATAMASH_EXE=$4

START_SUMMARY=`date '+%s'`

# GRAB THE START TIME

	echo start";" `date` \
	>| $INPUT_DIRECTORY/$INPUT_DIR_NAME"_DATA_SIZE_SUMMARY_START_"$TIME_STAMP".summary"

# PROJECT FOLDER SIZE BEFORE COMPRESSION

	du -s $INPUT_DIRECTORY \
		| awk '{print "before_compress;" "\t" $1/1024/1024,"Gb"}' \
	>> $INPUT_DIRECTORY/$INPUT_DIR_NAME"_DATA_SIZE_SUMMARY_START_"$TIME_STAMP".summary"

# CREATE A JSON FORMATTED STRING FOR THE TOP X NUMBER OF FILE EXTENSIONS BEFORE COMPRESSION
# WILL BE PARSED OUT LATER FOR END OF RUN SUMMARY

	find $INPUT_DIRECTORY -type f -exec du -a {} + \
		| awk 'BEGIN {FS="."} {print $1,$NF}' \
		| sed -r 's/[[:space:]]+/\t/g' \
		| sort -k 3,3 \
		| $DATAMASH_EXE -g 3 sum 1 \
		| sort -k 2,2nr \
		| awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$1"\x22," , "\x22value\x22"":" , "\x22"($2/1024/1024) , "Gb" "\x22" "}"  }' \
		| head -n $ROW_COUNT \
		| $DATAMASH_EXE collapse 1 \
		| awk 'BEGIN {FS=";"} {print "ext_b4_compress;" $1}' \
	>> $INPUT_DIRECTORY/$INPUT_DIR_NAME"_DATA_SIZE_SUMMARY_START_"$TIME_STAMP".summary"

# CREATE A JSON FORMATTED STRING FOR THE TOP X NUMBER OF FILE EXTENSIONS THAT HAVE ALREADY BEEN GZIPPED BEFORE THIS RUN.
# WILL BE PARSED OUT LATER FOR END OF RUN SUMMMARY

	find $INPUT_DIRECTORY -type f -name "*.gz" -exec du -a {} + \
		| awk 'BEGIN {FS="[./]";OFS="\t"} {print $1,$(NF-1)"."$NF}' \
		| sed -r 's/[[:space:]]+/\t/g' \
		| sort -k 2,2 \
		| DATAMASH_EXE -g 2 sum 1 \
		| sort -k 2,2nr \
		| awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$1"\x22," , "\x22value\x22"":" , "\x22"($2/1024/1024) , "Gb" "\x22" "}"  }' \
		| head -n $ROW_COUNT \
		| DATAMASH_EXE collapse 1 \
		| awk 'BEGIN {FS=";"} {print "ext_already_compressed;" $1}' \
	>> $INPUT_DIRECTORY/$INPUT_DIR_NAME"_DATA_SIZE_SUMMARY_START_"$TIME_STAMP".summary"

# CREATE A JSON FORMATTED STRING FOR THE TOP X NUMBER OF FILE EXTENSIONS THAT HAVE ALREADY BEEN GZIPPED BEFORE THIS RUN.
# WILL BE PARSED OUT LATER FOR END OF RUN SUMMMARY

	du -s $INPUT_DIRECTORY/*/ \
		| sort -k 1,1nr \
		| awk 'BEGIN {FS="/"} {print $1,$(NF-1)}' \
		|  awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$2"\x22," , "\x22value\x22"":" , "\x22"($1/1024/1024) , "Gb" "\x22" "}"  }' \
		| head \
		| DATAMASH_EXE collapse 1 \
		| awk 'BEGIN {FS=";"} {print "subfolder_start;" $1}' \
	>> $INPUT_DIRECTORY/$INPUT_DIR_NAME"_DATA_SIZE_SUMMARY_START_"$TIME_STAMP".summary"

END_SUMMARY=`date '+%s'`

echo $INPUT_DIR_NAM,START_SUMMARY,$HOSTNAME,$START_SUMMARY,$END_SUMMARY \
>> $DIR_TO_PARSE/COMPRESSOR.WALL.CLOCK.TIMES.csv
