#! /bin/bash

module load sge

DIR_TO_PARSE=$1 #Directory of the Project to compress
REF_GENOME=$2

SCRIPT_REPO=/isilon/sequencing/Kurt/GIT_REPO/BAM_TO_CRAM/COMPRESSION_SCRIPTS
DEFAULT_REF_GENOME=/isilon/sequencing/GATK_resource_bundle/1.5/b37/human_g1k_v37_decoy.fasta

QUEUE_LIST=`qstat -f -s r | egrep -v "^[0-9]|^-|^queue" | cut -d @ -f 1 | sort | uniq | egrep -v "bigmem.q|all.q|cgc.q|programmers.q|lemon.q" | datamash collapse 1 | awk '{print "-q",$1}'`

if [[ ! $REF_GENOME ]]
	then
	REF_GENOME=$DEFAULT_REF_GENOME
fi

####Uses bgzip to compress vcf file and tabix to index.  Also, creates md5 values for both####
 COMPRESS_AND_INDEX_VCF(){

	echo qsub $QUEUE_LIST -N COMPRESS_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/COMPRESS_AND_INDEX_VCF_$BASENAME.log $SCRIPT_REPO/compress_and_tabix_vcf.sh $FILE $DIR_TO_PARSE
}

####Uses samtools-1.4 to convert bam to cram and index and remove excess tags####  
BAM_TO_CRAM_CONVERSION_RND(){
	#Remove Tags + 5-bin Quality Score (RND Projects)
	 echo qsub $QUEUE_LIST -N BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_TO_CRAM_$BASENAME"_"$COUNTER.log $SCRIPT_REPO/bam_to_cram_remove_tags_rnd.sh $FILE $DIR_TO_PARSE $REF_GENOME $COUNTER
}

####Uses samtools-1.4 to convert bam to cram and index and remove excess tags####  
BAM_TO_CRAM_CONVERSION_PRODUCTION(){
	#Remove Tags
	 echo qsub $QUEUE_LIST -N BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_TO_CRAM_$BASENAME"_"$COUNTER.log $SCRIPT_REPO/bam_to_cram_remove_tags.sh $FILE $DIR_TO_PARSE $REF_GENOME 
}

####Uses ValidateSam to report any errors found within the original BAM file####
BAM_VALIDATOR(){
	echo qsub $QUEUE_LIST -N BAM_VALIDATOR_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_VALIDATOR_$BASENAME"_"$COUNTER.log $SCRIPT_REPO/bam_validation.sh $FILE $DIR_TO_PARSE $COUNTER
}

####Uses ValidateSam to report any errors found within the cram files####
CRAM_VALIDATOR(){
	echo qsub $QUEUE_LIST -N CRAM_VALIDATOR_$UNIQUE_ID -hold_jid BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/CRAM_VALIDATOR_$BASENAME"_"$COUNTER.log $SCRIPT_REPO/cram_validation.sh $FILE $DIR_TO_PARSE $REF_GENOME $COUNTER
}

####Parses through all CRAM_VALIDATOR files to determine if any errors/potentially corrupted cram files were created and creates a list in the top directory
VALIDATOR_COMPARER(){
	echo qsub $QUEUE_LIST -N VALIDATOR_COMPARE_$UNIQUE_ID -hold_jid "BAM_VALIDATOR_"$UNIQUE_ID",CRAM_VALIDATOR_"$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_CRAM_VALIDATE_COMPARE_$COUNTER.log $SCRIPT_REPO/bam_cram_validate_compare.sh $FILE $DIR_TO_PARSE $COUNTER
}

####Zips and md5s text and csv files####
ZIP_TEXT_AND_CSV_FILE(){
	echo qsub $QUEUE_LIST -N COMPRESS_\'$UNIQUE_ID\' -j y -o $DIR_TO_PARSE/LOGS/ZIP_FILE_\'$BASENAME\'.log $SCRIPT_REPO/zip_file.sh \'$FILE\' $DIR_TO_PARSE
}


BUILD_MD5_CHECK_HOLD_LIST(){
	MD5_HOLD_LIST=$MD5_HOLD_LIST'VALIDATOR_COMPARE_'$UNIQUE_ID','
}

####Compares MD5 between the original file and the zipped file (using zcat) to validate that the file was compressed successfully####
MD5_CHECK(){
	echo qsub $QUEUE_LIST -N MD5_CHECK_ENTIRE_PROJECT_$PROJECT_NAME -hold_jid $MD5_HOLD_LIST -j y -o $DIR_TO_PARSE/LOGS/MD5_CHECK.log $SCRIPT_REPO/md5_check.sh $DIR_TO_PARSE
}

MD5_CHECK_NO_HOLD_ID(){
	echo qsub $QUEUE_LIST -N MD5_CHECK_ENTIRE_PROJECT_$PROJECT_NAME -j y -o $DIR_TO_PARSE/LOGS/MD5_CHECK.log $SCRIPT_REPO/md5_check.sh $DIR_TO_PARSE
}

PROJECT_NAME=$(basename $DIR_TO_PARSE)
COUNTER=0
BAM_COUNTER=0

mkdir -p $DIR_TO_PARSE/MD5_REPORTS/
mkdir -p $DIR_TO_PARSE/LOGS
mkdir -p $DIR_TO_PARSE/TEMP

# Moved to bam_cram_validate_compare.sh and used an if statement to create only once.  Need to test!	
# echo -e SAMPLE\\tCRAM_CONVERSION_SUCCESS\\tCRAM_ONLY_ERRORS\\tNUMBER_OF_CRAM_ONLY_ERRORS >| $DIR_TO_PARSE/cram_conversion_validation.list

# Pass variable (vcf/txt/cram) file path to function and call $FILE within function#
for FILE in $(find $DIR_TO_PARSE -type f | egrep 'bam$' | egrep -v 'HC.bam$|[[:space:]]')
do
BASENAME=$(basename $FILE)
UNIQUE_ID=$(echo $BASENAME | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks
let COUNTER=COUNTER+1 # counter is used for some log or output names if there are multiple copies of a sample file within the directory as to not overwrite outputs
# if [[ $FILE == *".vcf" ]]
# then
# 	COMPRESS_AND_INDEX_VCF

if [[ $FILE == *".bam" ]]; then
	let BAM_COUNTER=BAM_COUNTER+1 # number will match the counter number used for logs and output files like bam/cram validation
	case $FILE in *02_CIDR_RND*)
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

# elif [[ $FILE == *".txt" ]]; then
# 	ZIP_TEXT_AND_CSV_FILE
# 
# elif [[ $FILE == *".csv" ]]; then
# 	ZIP_TEXT_AND_CSV_FILE
# 
# elif [[ $FILE == *".intervals" ]]; then
# 	ZIP_TEXT_AND_CSV_FILE
# 
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
