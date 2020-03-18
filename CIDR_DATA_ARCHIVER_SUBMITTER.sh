#! /bin/bash

# INPUT ARGUMENTS

	DIR_TO_PARSE=$1 #Directory of the Project to compress
		PROJECT_NAME=$(basename $DIR_TO_PARSE)
	REF_GENOME=$2 # optional. if not present then assumes grch37. full path

# OTHER VARIABLES

	# default genome is grch37 unless specified other as the 2nd argument to the script call

		DEFAULT_REF_GENOME=/mnt/research/tools/PIPELINE_FILES/bwa_mem_0.7.5a_ref/human_g1k_v37_decoy.fasta

			if [[ ! $REF_GENOME ]]
			then
				REF_GENOME=$DEFAULT_REF_GENOME
			fi


	# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED

		SUBMITTER_SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

		SCRIPT_REPO="$SUBMITTER_SCRIPT_PATH/COMPRESSION_SCRIPTS"

	# Generate a list of active queue and remove the ones that I don't want to use

		QUEUE_LIST=`qstat -f -s r \
			| egrep -v "^[0-9]|^-|^queue|^ " \
			| cut -d @ -f 1 \
			| sort \
			| uniq \
			| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q|bigdata.q|uhoh.q" \
			| datamash collapse 1 \
			| awk '{print $1}'`

	# SGE priority
		PRIORITY="-1023"

	# For job organization

		COUNTER=0
		BAM_COUNTER=0

# Make directories needed for processing if not already present

	mkdir -p $DIR_TO_PARSE/MD5_REPORTS/
	mkdir -p $DIR_TO_PARSE/LOGS
	mkdir -p $DIR_TO_PARSE/TEMP

# PIPELINE PROGRAMS

	TABIX_EXEC=/mnt/linuxtools/TABIX/tabix-0.2.6/tabix
	BGZIP_EXEC=/mnt/linuxtools/TABIX/tabix-0.2.6/bgzip
	GATK_DIR=/mnt/linuxtools/GATK/GenomeAnalysisTK-3.5-0
	JAVA_1_7=/mnt/linuxtools/JAVA/jdk1.7.0_25/bin
	SAMTOOLS_EXEC=/mnt/linuxtools/ANACONDA/anaconda2-5.0.0.1/bin/samtools
	PICARD_DIR=/mnt/linuxtools/PICARD/picard-tools-1.141
	DATAMASH_EXE=/mnt/linuxtools/DATAMASH/datamash-1.0.6/datamash

# Uses bgzip to compress vcf file and tabix to index.  Also, creates md5 values for both

	COMPRESS_AND_INDEX_VCF ()
		{
			echo \
			qsub $QUEUE_LIST \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N COMPRESS_$UNIQUE_ID \
				-j y \
				-o $DIR_TO_PARSE/LOGS/COMPRESS_AND_INDEX_VCF_$BASENAME.log \
			$SCRIPT_REPO/compress_and_tabix_vcf.sh \
				$FILE \
				$DIR_TO_PARSE \
				$TABIX_EXEC \
				$BGZIP_EXEC
		}

# Uses samtools-1.4+ to convert bam to cram and index and remove excess tags

	BAM_TO_CRAM_CONVERSION_RND ()
		{
			#Remove Tags + 5-bin Quality Score (RND Projects)
			 echo \
			 qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			 -N BAM_TO_CRAM_CONVERSION_$UNIQUE_ID \
				 -o $DIR_TO_PARSE/LOGS/BAM_TO_CRAM_$BASENAME"_"$COUNTER.log \
				 -j y \
			 $SCRIPT_REPO/bam_to_cram_remove_tags_rnd.sh \
				 $FILE \
				 $DIR_TO_PARSE \
				 $REF_GENOME \
				 $COUNTER \
				 $GATK_DIR \
				 $JAVA_1_7 \
				 $SAMTOOLS_EXEC
		}

# Uses samtools-1.4 (or higher) to convert bam to cram and index and remove excess tags

	BAM_TO_CRAM_CONVERSION_PRODUCTION ()
		{
			#Remove Tags
			 echo \
			 qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			 -N BAM_TO_CRAM_CONVERSION_$UNIQUE_ID \
				 -o $DIR_TO_PARSE/LOGS/BAM_TO_CRAM_$BASENAME"_"$COUNTER.log \
				 -j y \
			 $SCRIPT_REPO/bam_to_cram_remove_tags.sh \
				 $FILE \
				 $DIR_TO_PARSE \
				 $REF_GENOME \
				 $SAMTOOLS_EXEC
		}

# Uses ValidateSam to report any errors found within the original BAM file

	BAM_VALIDATOR ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N BAM_VALIDATOR_$UNIQUE_ID \
				-o $DIR_TO_PARSE/LOGS/BAM_VALIDATOR_$BASENAME"_"$COUNTER.log \
				-j y \
			$SCRIPT_REPO/bam_validation.sh \
				$FILE \
				$DIR_TO_PARSE \
				$COUNTER \
				$JAVA_1_7 \
				$PICARD_DIR
		}

# Uses ValidateSam to report any errors found within the cram files

	CRAM_VALIDATOR ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N CRAM_VALIDATOR_$UNIQUE_ID \
				-j y \
				-o $DIR_TO_PARSE/LOGS/CRAM_VALIDATOR_$BASENAME"_"$COUNTER.log \
			-hold_jid BAM_TO_CRAM_CONVERSION_$UNIQUE_ID \
			$SCRIPT_REPO/cram_validation.sh \
				$FILE \
				$DIR_TO_PARSE \
				$REF_GENOME \
				$COUNTER \
				$JAVA_1_7 \
				$PICARD_DIR
		}

# Parses through all CRAM_VALIDATOR files to determine if any errors/potentially corrupted cram files were created and creates a list in the top directory

	VALIDATOR_COMPARER ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N VALIDATOR_COMPARE_$UNIQUE_ID \
				-j y \
				-o $DIR_TO_PARSE/LOGS/BAM_CRAM_VALIDATE_COMPARE_$COUNTER.log \
			-hold_jid BAM_VALIDATOR"_"$UNIQUE_ID,CRAM_VALIDATOR"_"$UNIQUE_ID \
			$SCRIPT_REPO/bam_cram_validate_compare.sh \
				$FILE \
				$DIR_TO_PARSE \
				$COUNTER \
				$DATAMASH_EXE \
				$SAMTOOLS_EXEC
		}

# Zips and md5s text and csv files

	ZIP_TEXT_AND_CSV_FILE ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N COMPRESS_$UNIQUE_ID \
				-j y \
				-o $DIR_TO_PARSE/LOGS/"ZIP_FILE_"$BASENAME".log" \
			$SCRIPT_REPO/zip_file.sh \
				$FILE \
				$DIR_TO_PARSE
		}

# create a hold id for creating md5 checks

		BUILD_MD5_CHECK_HOLD_LIST ()
		{
			MD5_HOLD_LIST=$MD5_HOLD_LIST'VALIDATOR_COMPARE_'$UNIQUE_ID','
		}

# Compares MD5 between the original file and the zipped file (using zcat) to validate that the file was compressed successfully

	MD5_CHECK ()
		{
			echo \
			qsub\
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N MD5_CHECK_ENTIRE_PROJECT_$PROJECT_NAME \
				-j y \
				-o $DIR_TO_PARSE/LOGS/MD5_CHECK.log \
			-hold_jid $MD5_HOLD_LIST \
			$SCRIPT_REPO/md5_check.sh \
				$DIR_TO_PARSE
		}

	MD5_CHECK_NO_HOLD_ID ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N MD5_CHECK_ENTIRE_PROJECT_$PROJECT_NAME \
				-j y \
				-o $DIR_TO_PARSE/LOGS/MD5_CHECK.log \
			$SCRIPT_REPO/md5_check.sh \
				$DIR_TO_PARSE
		}

# Moved to bam_cram_validate_compare.sh and used an if statement to create only once.  Need to test!	
# echo -e SAMPLE\\tCRAM_CONVERSION_SUCCESS\\tCRAM_ONLY_ERRORS\\tNUMBER_OF_CRAM_ONLY_ERRORS >| $DIR_TO_PARSE/cram_conversion_validation.list

# Pass variable (vcf/txt/cram) file path to function and call $FILE within function

for FILE in $(find $DIR_TO_PARSE -type f | egrep 'bam$' | egrep -v 'HC.bam$|[[:space:]]')
	do
		BASENAME=$(basename $FILE)
		UNIQUE_ID=$(echo $BASENAME | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks

		let COUNTER=COUNTER+1 # counter is used for some log or output names if there are multiple copies of a sample file within the directory as to not overwrite outputs
		if [[ $FILE == *".vcf" ]]
			then
				COMPRESS_AND_INDEX_VCF

		if [[ $FILE == *".bam" ]]; then
			let BAM_COUNTER=BAM_COUNTER+1 # number will match the counter number used for logs and output files like bam/cram validation
			# case $FILE in *02_CIDR_RND*)
			case $FILE in *[Rr][Nn][Dd]*)

				BAM_TO_CRAM_CONVERSION_RND
				BAM_VALIDATOR
				CRAM_VALIDATOR
				VALIDATOR_COMPARER
				BUILD_MD5_CHECK_HOLD_LIST

			;;
				*)
				BAM_TO_CRAM_CONVERSION_PRODUCTION
				BAM_VALIDATOR
				CRAM_VALIDATOR
				VALIDATOR_COMPARER
				BUILD_MD5_CHECK_HOLD_LIST
			;;
			esac

		elif [[ $FILE == *".txt" ]]; then
			ZIP_TEXT_AND_CSV_FILE

		elif [[ $FILE == *".csv" ]]; then
			ZIP_TEXT_AND_CSV_FILE

		elif [[ $FILE == *".intervals" ]]; then
			ZIP_TEXT_AND_CSV_FILE

		else
			echo $FILE not being compressed

		fi
done

if [[ $BAM_COUNTER == 0 ]]
	then
		MD5_CHECK_NO_HOLD_ID
	else
		MD5_CHECK
fi
