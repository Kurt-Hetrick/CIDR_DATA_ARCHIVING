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

	DIR_TO_PARSE=$1
		PROJECT_NAME=$(basename $PROJECT)
	TIME_STAMP=$2
	ROW_COUNT=$3
	WEBHOOK=$4
	EMAIL=$5

# OTHER VARIABLES

	PROJECT_START_SUMMARY_FILE=$(ls DIR_TO_PARSE/$PROJECT_NAME"_DATA_SIZE_SUMMARY_START_"$TIME_STAMP".summary")
		START_DATE=$(grep "start;" $PROJECT_START_SUMMARY_FILE | awk 'BEGIN {FS="\t"} {print $2}')
		TOTAL_START_GB=$(grep "before_compress_Gb;" $PROJECT_START_SUMMARY_FILE | awk 'BEGIN {FS="\t"} {print $2}')
		EXT_BEFORE_COMPRESSION_SUMMARY=$(grep "ext_b4_compress;" $PROJECT_START_SUMMARY_FILE | awk 'BEGIN {FS="\t"} {print $2}')
		FILES_ALREADY_COMPRESSED_BEFORE_RUN_SUMMARY=$(grep "ext_already_compressed;" $PROJECT_START_SUMMARY_FILE | awk 'BEGIN {FS="\t"} {print $2}')
		SUBFOLDERS_BEFORE_COMPRESSION_SUMMARY=$(grep "subfolder_start;" $PROJECT_START_SUMMARY_FILE | awk 'BEGIN {FS="\t"} {print $2}')

START_FINISHING_SUMMARY=`date '+%s'`

##########################################################
##### Print out the message card header to json file #####
##########################################################

	printf \
		"{\n \
		\"@type\": \"MessageCard\",\n \
		\"@context\": \"http://schema.org/extensions\",\n \
		\"themeColor\": \"0078D7\",\n \
		\"summary\": \"Before and after project compression summary\", \n \
		\"sections\": [\n\
		{ \n\
			\"activityTitle\": \"Before Compression Summary for project\",\n\
				\"facts\": [\n\
		" \
	>| $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

#######################################################################################
##### Print out the overall before and after disk space summary and percent saved #####
#######################################################################################

	# project folder size after compression run

	# CALCULATE THE FOLDER SIZE AFTER THE RUN
	# CALCULATE THE PERCENT OF SPACE SAVED

		TOTAL_END_GB=$(du -s $DIR_TO_PARSE | awk '{print $1/1024/1024}')
		PERCENT_SAVED=$(echo "$TOTAL_END_GB / $TOTAL_START_GB" | bc -l)
		FINISHED_DATE=$(`date`)

	# print overall summary to json file

		printf \
			"{\n \
			\"name\": \"Project Folder\",\n \
			\"value\": \"$PROJECT\"\n \
			}, \n \
			{\n \
				\"name\": \"Start date\",\n \
				\"value\": \"$START_DATE\"\n \
			}, \n \
			{\n \
				\"name\": \"Finished date\",\n \
				\"value\": \"$FINISHED_DATE\"\n \
			}, \n \
			{\n \
				\"name\": \"BEFORE COMPRESSION\",\n \
				\"value\": \"$TOTAL_START_GB Gb\"\n \
			},\n \
			{\n \
				\"name\": \"AFTER COMPRESSION\",\n \
				\"value\": \"$TOTAL_END_GB Gb\"\n \
			},\n \
			{\n \
				\"name\": \"PERCENT SAVED\",\n \
				\"value\": \"$PERCENT_SAVED\"\n \
			}],\n \
			\"markdown\": true,\n \
			},\n \
			" \
		>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

###################################################################
##### Print out the file extension before compression summary #####
###################################################################

	printf \
		"{\n \
		\"activityTitle\": \"Top $ROW_COUNT file extensions by disk space used before compression:\",\n\
			\"facts\": [\n\
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	echo $EXT_BEFORE_COMPRESSION_SUMMARY \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	printf \
		"],\n \
		\"markdown\": true,\n \
		},\n \
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

##################################################################
##### Print out the file extension after compression summary #####
##################################################################

	printf \
		"{\n \
		\"activityTitle\": \"Top $ROW_COUNT file extensions by disk space used after compression:\",\n\
			\"facts\": [\n\
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	find $DIR_TO_PARSE -type f -exec du -a {} + \
		| awk 'BEGIN {FS="."} {print $1,$NF}' \
		| sed -r 's/[[:space:]]+/\t/g' \
		| sort -k 3,3 \
		| datamash -g 3 sum 1 \
		| sort -k 2,2nr \
		|  awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$1"\x22," , "\x22value\x22"":" , "\x22"($2/1024/1024) , "Gb" "\x22" "}"  }' \
		| head $ROW_COUNT \
		| datamash collapse 1 \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	printf \
		"],\n \
		\"markdown\": true,\n \
		},\n \
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

#################################################################################################
##### Print out the file extension that were already compressed before this compression run #####
#################################################################################################

	printf \
		"{\n \
		\"activityTitle\": \"Files that have already been gzipped before this compression run by original type (Top 15):\",\n\
			\"facts\": [\n\
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	echo $FILES_ALREADY_COMPRESSED_BEFORE_RUN_SUMMARY \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	printf \
		"],\n \
		\"markdown\": true,\n \
		},\n \
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

#################################################################################
##### Print out the top level subfolders disk space used before compression #####
#################################################################################

	printf \
		"{\n \
		\"activityTitle\": \"Top $ROW_COUNT first level subfolders by disk space used before compression:\",\n\
			\"facts\": [\n\
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	echo $SUBFOLDERS_BEFORE_COMPRESSION_SUMMARY \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	printf \
		"],\n \
		\"markdown\": true,\n \
		},\n \
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

################################################################################
##### Print out the top level subfolders disk space used after compression #####
################################################################################

	printf \
		"{\n \
		\"activityTitle\": \"Top $ROW_COUNT first level subfolders by disk space used after compression:\",\n\
			\"facts\": [\n\
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	du -s $DIR_TO_PARSE/*/ \
		| sort -k 1,1nr \
		| awk 'BEGIN {FS="/"} {print $1,$(NF-1)}' \
		|  awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$2"\x22," , "\x22value\x22"":" , "\x22"($1/1024/1024) , "Gb" "\x22" "}"  }' \
		| head $ROW_COUNT \
		| datamash collapse 1 \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

	printf \
		"],\n \
		\"markdown\": true\n \
		},\n \
		]\n \
		}\
		" \
	>> $DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json

#####################################
##### Send out summary to teams #####
#####################################

	curl -H "Content-Type: application/json" \
	--data @$DIR_TO_PARSE/$PROJECT_NAME_$TIME_STAMP_DATA_ARCHIVING_SUMMARY.json \
	$WEBHOOK

#############################################################
##### Send out notification if files failed to compress #####
#############################################################

	if [[ -f $DIR_TO_PARSE/failed_compression_jobs_other_files.list ]]
		then
			mail -s "FILES FAILED TO COMPRESS IN $PROJECT_NAME!" \
			$EMAIL \
			< $DIR_TO_PARSE/failed_compression_jobs_other_files.list
				sleep 2s
	fi

#################################################################
##### Send out notification if vcf files failed to compress #####
#################################################################

	if [[ -f $DIR_TO_PARSE/failed_compression_jobs_vcf.list ]]
		then
			mail -s "VCF FILES FAILED TO COMPRESS IN $PROJECT_NAME!" \
			$EMAIL \
			< $DIR_TO_PARSE/failed_compression_jobs_vcf.list
				sleep 2s
	fi

END_FINISHING_SUMMARY=`date '+%s'`

echo $PROJECT_NAME,FINISH_SUMMARY,$HOSTNAME,$START_FINISHING_SUMMARY,$END_FINISHING_SUMMARY \
>> $DIR_TO_PARSE/COMPRESSOR.WALL.CLOCK.TIMES.csv
