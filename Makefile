# paramterize the basex path so multiple people can use this
# cori requires: 'module load python'

# currently only intended to create SQLite db file
#   not Parquet, or EAV TSVs as specified in biosample-analysis, etc.

# make a document about which terms (harmonized attribute, non-harmonized attribute or non-attriubte) go into queries/biosample_non-attribute_plus_emp500_wide.xq
#   and make all attributes/harmonized attributes options for the long/EAV query?


# add steps for zipping sSQLite database and deleting it in clean step

.PHONY: all biosample-basex chunk_harmonized_attributes_long clean count_clean wide_chunks wide_ha_chunks_to_sqlite

all: clean target/biosample_set.xml biosample-basex target/biosample_non_harmonized_attributes_wide.tsv chunk_harmonized_attributes_long chunk_harmonized_attributes_long wide_chunks wide_ha_chunks_to_sqlite target/biosample_basex.db target/biosample_basex.db.gz

clean:
	# not wiping or overwriting BaseX database as part of 'clean'
	rm -rf downloads/*.gz
	# rm -rf target/*
	rm -rf target/chunks_long/*.tsv
	rm -rf target/chunks_wide/*.tsv
	rm -rf target/*.tsv
	rm -rf target/*.db
	rm -rf target/*.txt
	rm -rf target/*.gz


export PROJDIR=/global/cfs/cdirs/m3513/endurable/biosample/mam
export BASEXCMD=$(PROJDIR)/biosample-basex/basex/bin/basex

# work on file and variable naming conventions
# capitalization
# count X by Y
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

# 35 minutes
target/biosample_non_harmonized_attributes_wide.tsv:
	date ; time $(BASEXCMD) queries/biosample_non_harmonized_attributes_wide.xq > $@

# ---

chunk_harmonized_attributes_long:
	util/chunk_harmonized_attributes_long.sh

# ---

# PARAMETERIZE OUT THE HARDCODED PATHS
# here and elsewhere
wide_chunks: chunk_harmonized_attributes_long
	python3 util/make_wide_ha_chunks.py

# ---

wide_ha_chunks_to_sqlite: wide_chunks
	python3 util/wide_ha_chunks_to_sqlite.py

# ---

# how far do we want to go with dependencies?
# esp when they are phony?
target/biosample_basex.db: target/biosample_non_harmonized_attributes_wide.tsv wide_ha_chunks_to_sqlite
	sqlite3 target/biosample_basex.db ".mode tabs" ".import target/biosample_non_harmonized_attributes_wide.tsv non_harmonized_attributes" ""
	sqlite3 target/biosample_basex.db 'CREATE INDEX non_harmonized_attributes_raw_id_idx on non_harmonized_attributes("raw_id")' ''
	sqlite3 target/biosample_basex.db 'CREATE INDEX catted_wide_harmonized_attributes_raw_id_idx on catted_wide_harmonized_attributes("raw_id")' ''
	# what kind of join? full outer tricky in sqlite?
	# gets some nulls in harmonized attribute columns
	sqlite3 target/biosample_basex.db 'CREATE VIEW biosample_basex_merged AS SELECT * FROM non_harmonized_attributes LEFT JOIN catted_wide_harmonized_attributes using("raw_id")' ''
	sqlite3 target/biosample_basex.db "select * from biosample_basex_merged where raw_id > 9 and raw_id < 999 limit 3" > target/test_query_result.txt

# ---

# depends on target/biosample_basex.db and a previous-generation harmonized_table.db
# path currently hardcoded
target/column_differences.txt:
	python util/column_differences.py > $@

# ---
# depends on target/biosample_basex.db and wide_ha_chunks_to_sqlite, 
#   but want to be careful about adding duplicate rows 
#   or nuking the rows that are added live by wide_ha_chunks_to_sqlite
#   although they are stagews as wide chunks, too
target/biosample_basex.db.gz: 
	# depends on target/biosample_basex.db
	gzip -c target/biosample_basex.db > $@
	chmod 777 $@

# factor out this hardcoded path
# available at https://portal.nersc.gov/project/m3513/biosample
# https://stackoverflow.com/questions/6824717/sqlite-how-do-you-join-tables-from-different-databases
/global/cfs/cdirs/m3513/www/biosample/biosample_basex.db.gz: target/biosample_basex.db.gz
	cp $< $@
	chmod 777 $@

# ---

target/all_biosample_attributes_values.tsv:
	date ; time $(BASEXCMD) queries/all_biosample_attributes_values.xq > $@

# ---

target/SRA_Run_Members.tab:
	curl https://ftp.ncbi.nlm.nih.gov/sra/reports/Metadata/SRA_Run_Members.tab --output $@

# an index on biosample_basex.db.non_harmonized_attributes.emp500_title will help, too
target/SRA_Run_Members.db: target/SRA_Run_Members.tab
	sqlite3 $@ ".mode tabs" ".import $< SRA_Run_Members" ""
	sqlite3 $@ 'CREATE INDEX Sample_idx on SRA_Run_Members("Sample")' ''

target/SRA_Run_Members.db.gz: target/SRA_Run_Members.db
	gzip -c $< > $@

/global/cfs/cdirs/m3513/www/biosample/SRA_Run_Members.db.gz: target/SRA_Run_Members.db.gz
	cp $< $@
	chmod 777 $@

target/biosample_srrs.txt:
	sqlite3 ".mode tabs" "attach 'target/biosample_basex.db' as bb ; attach 'target/SRA_Run_Members.db' as srm ; select nha.sra_id, rm.Run from bb.non_harmonized_attributes nha left join srm.SRA_Run_Members rm on rm.Sample = nha.sra_id where rm.Run is not null order by nha.sra_id, rm.Run" "" > $@

# index biosample_basex.db.non_harmonized_attributes.emp500_title?

# attach 'SRA_Run_Members.db' as srm;

# select
# 	sra_id,
# 	srm.non_harmonized_attributes.Run
# from
# 	non_harmonized_attributes
# left join srm.non_harmonized_attributes on
# 	srm.non_harmonized_attributes.Sample = non_harmonized_attributes.sra_id
# where
# 	emp500_title is not null
# 	and emp500_title != '';

# select
# 	taxonomy_name,
# 	count(1)
# from
# 	non_harmonized_attributes nha
# where
# 	emp500_title is not null
# 	and emp500_title != ''
# group by
# 	taxonomy_name
# order by
# 	taxonomy_name;

# |taxonomy_name|count(1)|
# |-------------|--------|
# |activated sludge metagenome|17|
# |algae metagenome|49|
# |bioreactor metagenome|9|
# |coal metagenome|16|
# |coral metagenome|20|
# |freshwater sediment metagenome|47|
# |gut metagenome|199|
# |insect metagenome|28|
# |lichen metagenome|12|
# |marine metagenome|37|
# |marine sediment metagenome|66|
# |metagenome|2|
# |microbial mat metagenome|1|
# |mollusc metagenome|13|
# |mouse skin metagenome|3|
# |oil field metagenome|14|
# |plant metagenome|15|
# |salt marsh metagenome|24|
# |sand metagenome|9|
# |seawater metagenome|2|
# |soil metagenome|189|
# |sponge metagenome|57|
# |stromatolite metagenome|1|

# |taxonomy_name                 |count(1)|
# |------------------------------|--------|
# |gut metagenome                |199     |
# |soil metagenome               |189     |
# |marine sediment metagenome    |66      |
# |sponge metagenome             |57      |
# |algae metagenome              |49      |
# |freshwater sediment metagenome|47      |
# |marine metagenome             |37      |
# |insect metagenome             |28      |
# |salt marsh metagenome         |24      |
# |coral metagenome              |20      |
# |activated sludge metagenome   |17      |
# |coal metagenome               |16      |
# |plant metagenome              |15      |
# |oil field metagenome          |14      |
# |mollusc metagenome            |13      |
# |lichen metagenome             |12      |
# |bioreactor metagenome         |9       |
# |sand metagenome               |9       |
# |mouse skin metagenome         |3       |
# |metagenome                    |2       |
# |seawater metagenome           |2       |
# |microbial mat metagenome      |1       |
# |stromatolite metagenome       |1       |



# ---

# add EMP Ontology terms to non-attributes query ???
# empo_0
# empo_1
# empo_2
# empo_3

# ---

count_clean:
	rm -rf target/count_biosamples.tsv

# 2 million biosamples 20211004
# 2 minutes
target/count_biosamples.tsv:
	date ; time $(BASEXCMD) queries/count_biosamples.xq | tee $@

# ---

# deprecated in favor of chunk_harmonized_attributes_long shell script
target/biosample_harmonized_attributes_long.tsv:
	date ; time $(BASEXCMD) queries/biosample_harmonized_attributes_long.xq > $@

# ---

