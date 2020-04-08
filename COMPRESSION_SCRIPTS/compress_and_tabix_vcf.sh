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

	VCF_FILES=$1
	DIR_TO_PARSE=$2
		PROJECT_NAME=$(basename $DIR_TO_PARSE)
	TABIX_EXEC=$3
	BGZIP_EXEC=$4

START_COMPRESS_VCF=`date '+%s'`

	# compress vcf with bgzip and create tbi index
	# compare md5sum before and after compression. if the same, then delete the uncompressed file.

		COMPRESS_AND_VALIDATE ()
			{
				# GET THE MD5 BEFORE COMPRESSION

					ORIGINAL_MD5=$(md5sum $IN_VCF | awk '{print $1}')

				# BGZIP THE FILE AND INDEX IT

					# if any part of pipe fails set exit to non-zero

						set -o pipefail

					$BGZIP_EXEC \
						-c \
						--threads 4 \
						$IN_VCF \
					> $IN_VCF.gz \
						&& \
					$TABIX_EXEC\
						-h $IN_VCF.gz

				# GET THE MD5 AFTER COMPRESSION

					COMPRESSED_MD5=$(md5sum $IN_VCF.gz)

				# write both md5 to files

					echo $COMPRESSED_MD5 >> $DIR_TO_PARSE/MD5_REPORTS/compressed_md5_vcf.list
					echo $ORIGINAL_MD5 $IN_VCF >> $DIR_TO_PARSE/MD5_REPORTS/original_md5_vcf.list

				# check md5sum of zipped file using zcat

					ZIPPED_MD5=$(zcat $IN_VCF.gz | md5sum | awk '{print $1}')

				# if md5 matches delete the uncompressed file

					if [[ $ORIGINAL_MD5 = $ZIPPED_MD5 ]]
						then
							echo "$IN_VCF" compressed successfully >> $DIR_TO_PARSE/successful_compression_jobs_vcf.list
							rm -rvf "$IN_VCF"
						else
							echo "$IN_VCF" did not compress successfully >> $DIR_TO_PARSE/failed_compression_jobs_vcf.list
					fi

				# delete the tribble index for the uncompressed file

					rm -f $IN_VCF".idx"
			}

	export -f COMPRESS_AND_VALIDATE

	for IN_VCF in $(cat $VCF_FILES);
		do COMPRESS_AND_VALIDATE
	done

END_COMPRESS_VCF=`date '+%s'`

echo $PROJECT_NAME,COMPRESS_AND_INDEX_VCF,$HOSTNAME,$START_COMPRESS_VCF,$END_COMPRESS_VCF \
>> $DIR_TO_PARSE/COMPRESSOR.WALL.CLOCK.TIMES.csv
