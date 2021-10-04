.PHONY: biosample-basex
.PHONY: count-biosamples

export PROJDIR=/global/cfs/cdirs/m3513/endurable/biosample/mam
export BASEXCMD=$(PROJDIR)/biosample-basex/basex/bin/basex

# work on file and variable naming conventions
# capitalization
# count X by Y
# use CSV serializer wherever possible, not string concatenation
# make sure that the same dataset is being used in all queries

# be consistent about identifying samples with accession or primary ID

# 2021-06-15: 1.3 GB
# roughly 1 minute
downloads/biosample_set.xml.gz:
	# wget ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz
	curl ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz --output $@

# 2021-06-15: 44 GB
# 731549545 text LINES (not entity count)
# roughly 2 minutes
target/biosample_set.xml: downloads/biosample_set.xml.gz
	gunzip -c $< > $@

# UPDATE THESE STATS and database file location
# ~ 40 minutes @ Xmx  = 24 GB RAM
# ~ 45 GB
biosample-basex: target/biosample_set.xml
	$BASEXCMD -c 'CREATE DB biosample_set target/biosample_set.xml'

count-biosamples:
	date ; time $(BASEXCMD) queries/count_biosamples.xq
