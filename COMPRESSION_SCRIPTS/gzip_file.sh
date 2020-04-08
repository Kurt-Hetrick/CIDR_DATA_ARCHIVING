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

	IN_FILES=$1
	DIR_TO_PARSE=$2
		PROJECT_NAME=$(basename $DIR_TO_PARSE)
	PIGZ_MODULE=$3
		module load $PIGZ_MODULE

START_GZIP=`date '+%s'`

	# compare md5sum before and after compression. if the same, then delete the uncompressed file.

	COMPRESS_AND_VALIDATE ()
		{
			# GET THE MD5 BEFORE COMPRESSION

				ORIGINAL_MD5=$(md5sum $FILE | awk '{print $1}')

			# BGZIP THE FILE AND INDEX IT

				# if any part of pipe fails set exit to non-zero

					pigz -c -p 4 $FILE >| $FILE.gz

			# GET THE MD5 AFTER COMPRESSION

				COMPRESSED_MD5=$(md5sum $FILE.gz)

			# check md5sum of zipped file using zcat

				ZIPPED_MD5=$(zcat $FILE.gz | md5sum | awk '{print $1}')

			# write both md5 to files

				echo $COMPRESSED_MD5 >> $DIR_TO_PARSE/MD5_REPORTS/compressed_md5_other_files.list
				echo $ORIGINAL_MD5 $FILE >> $DIR_TO_PARSE/MD5_REPORTS/original_md5_other_files.list

			# if md5 matches delete the uncompressed file

				if [[ $ORIGINAL_MD5 = $ZIPPED_MD5 ]]
					then
						echo "$FILE" compressed successfully >> $DIR_TO_PARSE/successful_compression_jobs_other_files.list
						rm -rvf "$FILE"
					else
						echo "$FILE" did not compress successfully >> $DIR_TO_PARSE/failed_compression_jobs_other_files.list
				fi
		}

	export -f COMPRESS_AND_VALIDATE

	for FILE in $(cat $IN_FILES);
		do COMPRESS_AND_VALIDATE
	done


END_GZIP=`date '+%s'`

 echo $PROJECT_NAME,PIGZ,$HOSTNAME,$START_GZIP,$END_GZIP \
 >> $DIR_TO_PARSE/COMPRESSOR.WALL.CLOCK.TIMES.csv
