
PROJECT=$1



START_DATE=$(grep FILE)
TOTAL_START_GB=$(grep FILE)





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
"

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
		\"name\": \"BEFORE COMPRESSION\",\n \
		\"value\": \"$TOTAL_START_GB\"\n \
	}],\n \
	\"markdown\": true,\n \
	},\n \
	"

printf \
	"{\n \
	\"activityTitle\": \"Top 15 file extensions by disk space used:\",\n\
		\"facts\": [\n\
	"


find /path/to/project/ -type f -exec du -a {} + \
	| awk 'BEGIN {FS="."} {print $1,$NF}' \
	| sed -r 's/[[:space:]]+/\t/g' \
	| sort -k 3,3 \
	| datamash -g 3 sum 1 \
	| sort -k 2,2nr \
	|  awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$1"\x22," , "\x22value\x22"":" , "\x22"($2/1024/1024) , "Gb" "\x22" "}"  }' \
	| head \
	| datamash collapse 1

printf \
"],\n \
\"markdown\": true,\n \
},\n \
"

printf \
	"{\n \
	\"activityTitle\": \"Files that have already been gzipped before this compression run by original type (Top 15):\",\n\
		\"facts\": [\n\
	"

find /path/to/project/ -type f -name "*.gz" -exec du -a {} + \
	| awk 'BEGIN {FS="[./]";OFS="\t"} {print $1,$(NF-1)"."$NF}' \
	| sed -r 's/[[:space:]]+/\t/g' \
	| sort -k 2,2 \
	| datamash -g 2 sum 1 \
	| sort -k 2,2nr \
	|  awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$1"\x22," , "\x22value\x22"":" , "\x22"($2/1024/1024) , "Gb" "\x22" "}"  }' \
	| head

printf \
"],\n \
\"markdown\": true,\n \
},\n \
"

printf \
	"{\n \
	\"activityTitle\": \"Top 15 subfolders by disk space used:\",\n\
		\"facts\": [\n\
	"

du -s /path/to/project/*/ \
	| sort -k 1,1nr \
	| awk 'BEGIN {FS="/"} {print $1,$(NF-1)}' \
	|  awk '{print "{" "\x22" "name" "\x22" ":" , "\x22"$2"\x22," , "\x22value\x22"":" , "\x22"($1/1024/1024) , "Gb" "\x22" "}"  }' \
	| head \
	| datamash collapse 1

printf \
"],\n \
\"markdown\": true\n \
},\n \
]\n \
}\
"
