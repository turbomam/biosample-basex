# paramterize the basex path so multiple people can use this
# cori requires: 'module load python'

# modify clean steps so that they don't delete readmes
# add additional targetd cleanup steps

# currently only intended to create SQLite db file
#   not Parquet, or EAV TSVs as specified in biosample-analysis, etc.

# make a document about which terms (harmonized attribute, non-harmonized attribute or non-attriubte) go into queries/biosample_non-attribute_plus_emp500_wide.xq
#   and make all attributes/harmonized attributes options for the long/EAV query?

# add harmonized name accounting

.PHONY: biosample-basex count-biosamples clean count_clean all chunk_harmonized_attributes_long wide_chunks catted_chunks

all: clean biosample-basex target/biosample_non_harmonized_attributes_wide.tsv chunk_harmonized_attributes_long wide_chunks catted_chunks

clean:
	# not wiping or overwriting BaseX database as part of 'clean'
	rm -rf downloads/*
	# rm -rf target/*
	rm -rf target/chunks_long/*.tsv
	rm -rf target/chunks_wide/*.tsv
	

export PROJDIR=/global/cfs/cdirs/m3513/endurable/biosample/mam
export BASEXCMD=$(PROJDIR)/biosample-basex/basex/bin/basex

# work on file and variable naming conventions
# capitalization
# count X by Y
# use CSV serializer wherever possible, not string concatenation
# make sure that the same dataset is being used in all queries

# be consistent about identifying samples with accession or primary ID
	
# ---

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
	
# ---

count_clean:
	rm -rf target/count_biosamples.tsv

# 2 million biosamples 20211004
# 2 minutes
target/count_biosamples.tsv:
	date ; time $(BASEXCMD) queries/count_biosamples.xq | tee $@
	
# ---

# 35 minutes
target/biosample_non_harmonized_attributes_wide.tsv:
	date ; time $(BASEXCMD) queries/biosample_non_harmonized_attributes_wide.xq > $@
	
# ---

# deprecated in favor of chunk_harmonized_attributes_long
target/biosample_harmonized_attributes_long.tsv:
	date ; time $(BASEXCMD) queries/biosample_harmonized_attributes_long.xq > $@
	
# ---

chunk_harmonized_attributes_long:
	util/chunk_harmonized_attributes_long.sh
	
# ---

# PARAMETERIZE OUT THE HARDCODED PATHS
# here and elsewhere
wide_chunks: chunk_harmonized_attributes_long
	python3 util/make_wide_ha_chunks.py
	
# ---

catted_chunks: wide_chunks
	python3 util/cat_wide_ha_chunks.py
	
# ---

# how far do we watn to go with dependencies?
# esp when they are phony?
#  target/biosample_non_harmonized_attributes_wide.tsv catted_chunks
populate_sqlite_etc: 
	sqlite3 target/biosample_basex.db ".mode tabs" ".import target/biosample_non_harmonized_attributes_wide.tsv non_harmonized_attributes" ""
	# sqlite3 target/biosample_basex.db ".mode tabs" ".import target/catted_wide_harmonized_attributes.tsv catted_wide_harmonized_attributes" ""
	sqlite3 target/biosample_basex.db 'CREATE INDEX non_harmonized_attributes_raw_id_idx on non_harmonized_attributes("raw_id")' ''
	sqlite3 target/biosample_basex.db 'CREATE INDEX catted_wide_harmonized_attributes_raw_id_idx on catted_wide_harmonized_attributes("raw_id")' ''
	# what kind of join? full outer tricky in sqlite?
	sqlite3 target/biosample_basex.db 'CREATE VIEW biosample_basex_merged AS SELECT * FROM non_harmonized_attributes LEFT JOIN catted_wide_harmonized_attributes using("raw_id")' ''
	# lite3 target/biosample_basex.db
	# sqlite> select * from biosample_basex_merged where "raw_id" > 9 and "raw_id" < 999 limit 3;
	
# ---

# add EMP Ontology terms to non-attributes query ???
# empo_0
# empo_1
# empo_2
# empo_3

