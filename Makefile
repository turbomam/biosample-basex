# currently only intended to create SQLite db file
#   not Parquet, or EAV TSVs as specified in biosample-analysis, etc.

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

# 20211004: 1.5 GB
# roughly 1 minute
downloads/biosample_set.xml.gz:
	# wget ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz
	curl ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz --output $@

# 2021-06-15: 51 GB
# roughly 2 minutes
target/biosample_set.xml: downloads/biosample_set.xml.gz
	gunzip -c $< > $@

# ~ 90 minutes on cori @ Xmx  = 96 GB RAM. Xmx may not matter much for load. But indexing?
# du -sh $PROJDIR/biosample-basex/basex/data/biosample_set/: 52G
biosample-basex: target/biosample_set.xml
	$(BASEXCMD) -c 'CREATE DB biosample_set target/biosample_set.xml'

# 2 million biosamples 20211004
# 2 minutes
target/count_biosamples.tsv:
	date ; time $(BASEXCMD) queries/count_biosamples.xq | tee $@

# 35 minutes
target/biosample_non-attribute_plus_emp500_wide.tsv:
	date ; time $(BASEXCMD) queries/biosample_non-attribute_plus_emp500_wide.xq > $@
	
# add to non-attributes query
# empo_0 ???
# empo_1 ???
# empo_2 ???
# empo_3 ???

