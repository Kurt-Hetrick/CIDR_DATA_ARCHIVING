printf \
	"{\n \
	\"@type\": \"MessageCard\",\n \
	\"@context\": \"http://schema.org/extensions\",\n \
	\"themeColor\": \"0078D7\",\n \
	\"summary\": \"Before and after project compression summary\", \n \
	\"sections\": [\n\
	{ \n\
		\"activityTitle\": \"Before Compression Summary for M&#95Valle&#95MendelianDisorders&#95SeqWholeExome_120511_20\",\n\
			\"facts\": [\n\
"

printf \
	"{\n \
	\"name\": \"Project Folder\",\n \
	\"value\": \"M_Valle_MendelianDisorders_SeqWholeExome_120511_20\"\n \
	}, \n \
	{\n \
		\"name\": \"Start date\",\n \
		\"value\": \"Fri Mar 20 16:02:37 EDT 2020\"\n \
	}, \n \
	{\n \
		\"name\": \"BEFORE COMPRESSION\",\n \
		\"value\": \"205.561\"\n \
	}],\n \
	\"markdown\": true,\n \
	},\n \
	"

printf \
	"{\n \
	\"activityTitle\": \"Top 15 extensions\",\n\
		\"facts\": [\n\
	"


find /mnt/research/completed/04_MENDEL/M_Valle_MendelianDisorders_SeqWholeExome_120511_20/ -type f -exec du -a {} + \
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
	\"activityTitle\": \"Top 15 subfolders\",\n\
		\"facts\": [\n\
	"

du -s /mnt/research/completed/04_MENDEL/M_Valle_MendelianDisorders_SeqWholeExome_120511_20/*/ \
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
