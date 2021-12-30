del_from = 12500001
biosample_url = https://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz
BASEXCMD = basex

# rearrange xq and sql files

##export PROJDIR=/global/cfs/cdirs/m3513/endurable/biosample/mam
##export BASEXCMD=$(PROJDIR)/biosample-basex/basex/bin/basex

## just require that basex binaries are on the path?
## and use the default data directory?
## remember that we will be looping over all databases for some queries

## work on file and variable naming conventions
## capitalization
## count X by Y

.PHONY: all clean biosample-basex

all: clean biosample-basex target/biosample_basex.db

clean:
	# not wiping or overwriting BaseX database as part of 'clean'
	rm -f downloads/*.gz
	rm -f target/*.db
	rm -f target/*.tsv
	rm -f target/biosample_set_over_$(del_from)*.xml
	rm -f target/biosample_set_under_$(del_from)*.xml

target/biosample_basex.db:
	# 	date ; time
	sqlite3 target/biosample_basex.db < all_attribs.sql
	sqlite3 target/biosample_basex.db < non_attribute_metadata.sql
	$(BASEXCMD) queries/all_biosample_attributes_values_by_raw_id.xq > target/all_biosample_attributes_values_by_raw_id.tsv
	$(BASEXCMD) queries/biosample_non_attribute_metadata_wide.xq > target/biosample_non_attribute_metadata_wide.tsv
	sqlite3 target/biosample_basex.db ".mode tabs" ".import --skip 1 target/all_biosample_attributes_values_by_raw_id.tsv all_attribs" ""
	sqlite3 target/biosample_basex.db ".mode tabs" ".import --skip 1 target/biosample_non_attribute_metadata_wide.tsv non_attribute_metadata" ""
	python3 util/extract_harmonizeds.py
	sqlite3 target/biosample_basex.db < harmonized_wide_raw_id_idx.sql
	sqlite3 target/biosample_basex.db < harmonized_wide_env_package_idx.sql
	sqlite3 target/biosample_basex.db < env_package_repair_ddl.sql
	sqlite3 target/biosample_basex.db ".mode tabs" ".import --skip 1 target/env_package_repair_curated.tsv env_package_repair" ""
	sqlite3 target/biosample_basex.db < harmonized_wide_repaired_ddl.sql

target/env_package_repair_new.tsv: target/biosample_basex.db
	sqlite3 -readonly -csv -header -separator $$'\t' $< < env_package_repair.sql > $@

# 20211004: 1.5 GB
# roughly 1 minute
downloads/biosample_set.xml.gz:
	# wget ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz
	curl ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz --output $@

# 2021-06-15: 51 GB
# roughly 2 minutes
target/biosample_set.xml: downloads/biosample_set.xml.gz
	gunzip -c $< > $@

target/biosample_set_under_$(del_from)_noclose.xml: target/biosample_set.xml
	# two minutes when retrieving 12500000 lines
	date
	sed '/^<BioSample.*id="$(del_from)"/q'  $< > $@
	# below might not require deletion of trailing line
	# not that that's a slow step
	#sed '/^<BioSample.*id="$(del_from)"/,$$d'  $< > $@
	date

target/biosample_set_under_$(del_from).xml: target/biosample_set_under_$(del_from)_noclose.xml
	# sed's q operator leaves the matching line
	# this deletes the unwanted matching line
	# note $$ escaping within make
	sed -i.bak '$$d' $<
	# another two minutes when retrieving 12500000 lines
	cat $< biosample_set_closer.txt > $@
	rm -f $<
	# DELETE BACKUP FILE

target/biosample_set_over_$(del_from)_noopen.xml: target/biosample_set.xml
	sed -n '/^<BioSample.*id="$(del_from)"/,$$p'  $< > $@

target/biosample_set_over_$(del_from).xml: target/biosample_set_over_$(del_from)_noopen.xml
	cat biosample_set_opener.txt $< > $@
	rm -f $<

# ~ 90 minutes on cori @ Xmx  = 96 GB RAM. Xmx may not matter much for load. But indexing?
# du -sh $PROJDIR/biosample-basex/basex/data/biosample_set/: 52G
biosample-basex: target/biosample_set_under_$(del_from).xml target/biosample_set_over_$(del_from).xml
	$(BASEXCMD) -c 'CREATE DB biosample_set_1 target/biosample_set_under_$(del_from).xml'
	$(BASEXCMD) -c 'CREATE DB biosample_set_2 target/biosample_set_over_$(del_from).xml'
