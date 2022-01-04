## using .env for
#del_from = 12500001
#biosample_url = https://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz
#BASEXCMD = ???
#final_sqlite_gz_dest = ???

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# ---

# https://stackoverflow.com/questions/6824717/sqlite-how-do-you-join-tables-from-different-databases

## uses the default BaseX data directory
## remember that we will be looping over all databases for some queries

# TODO rearrange xq and sql file folders
## work on file and variable naming conventions
## capitalization
## count X by Y

.PHONY: remind all clean biosample-basex check_env final_sqlite_gz_dest ha_highlights_reports basex_reports sqlite_reports bio_project

remind:
	@echo
	@echo "DON'T FORGET 'module load python/3.9-anaconda-2021.11' FOR CORI OR 'source venv/bin/activate' FOR OTHER SYSTEMS"
	@echo "DON'T FORGET 'screen' FOR REMOTE SYSTEMS INCLUDING CORI"
	@echo
	-module list
	-pip list | grep pandas
	-screen -ls

all: remind clean check_env \
	biosample-basex basex_reports \
	target/biosample_basex.db target/env_package_repair_new.tsv sqlite_reports \
	target/biosample_basex.db.gz

# doesn't include final_sqlite_gz_dest

# not cleaning out previous reports yet
# ha_highlights_reports fails on cori
#   value_counts() got an unexpected keyword argument 'dropna'
sqlite_reports: reports/grow_facil_pattern.tsv reports/sam_coll_meth_pattern.tsv ha_highlights_reports

basex_reports: reports/basex_list.txt \
	reports/biosample_set_1_info_db.txt reports/biosample_set_1_info_index.txt \
	reports/biosample_set_2_info_db.txt reports/biosample_set_2_info_index.txt

check_env:
	echo ${del_from}
	echo ${biosample_url}
	echo ${BASEXCMD}
	echo ${final_sqlite_gz_dest}

clean:
	${BASEXCMD} -c 'drop db biosample_set_*'
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
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import --skip 1 target/all_biosample_attributes_values_by_raw_id.tsv all_attribs" ""
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import --skip 1 target/biosample_non_attribute_metadata_wide.tsv non_attribute_metadata" ""
	python3 util/extract_harmonizeds.py
	sqlite3 target/biosample_basex.db < harmonized_wide_raw_id_idx.sql
	sqlite3 target/biosample_basex.db < harmonized_wide_env_package_idx.sql
	sqlite3 target/biosample_basex.db < env_package_repair_ddl.sql
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import --skip 1 env_package_repair_curated.tsv env_package_repair" ""
	sqlite3 target/biosample_basex.db < harmonized_wide_repaired_ddl.sql
	sqlite3 target/biosample_basex.db \
		'CREATE VIEW biosample_basex_merged AS SELECT * FROM non_attribute_metadata LEFT JOIN harmonized_wide using("raw_id"))' ''



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
	#sed '/^<BioSample.*id="$(del_from)"/q'  $< > $@
	# below might not require deletion of trailing line
	# not that that's a slow step
	sed '/^<BioSample.*id="$(del_from)"/,$$d'  $< > $@
	date

target/biosample_set_under_$(del_from).xml: target/biosample_set_under_$(del_from)_noclose.xml
	# sed's q operator leaves the matching line
	# this deletes the unwanted matching line
	# note $$ escaping within make
	#sed -i.bak '$$d' $<
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

# ----

# depends on target/biosample_basex.db
#   but want to be careful about adding duplicate rows to SQLite
#   or nuking any rows
target/biosample_basex.db.gz:
	gzip -c target/biosample_basex.db > $@
	chmod 777 $@

# on cori, /global/cfs/cdirs/m3513/www/biosample is exposed at https://portal.nersc.gov/project/m3513/biosample
final_sqlite_gz_dest: target/biosample_basex.db.gz
	cp $< ${final_sqlite_gz_dest}
	chmod 777 ${final_sqlite_gz_dest}

# ----

reports/grow_facil_pattern.tsv:
	python util/investigate_unharmonized.py \
		--pattern %grow%facil% \
		--database_file target/biosample_basex.db \
		--output_file $@

reports/sam_coll_meth_pattern.tsv:
	python util/investigate_unharmonized.py \
		--pattern %sam%coll%meth% \
		--database_file target/biosample_basex.db \
		--output_file $@

ha_highlights_reports:
	python util/ha_highlights.py \
		--database_file target/biosample_basex.db \
		--output_dir reports

reports/basex_list.txt:
	$(BASEXCMD) -c "list" > $@

# hardcoded db and target
reports/biosample_set_1_info_db.txt:
	$(BASEXCMD) -c "open biosample_set_1 ; info db" > $@

# hardcoded db and target
reports/biosample_set_2_info_db.txt:
	$(BASEXCMD) -c "open biosample_set_2 ; info db" > $@

# hardcoded db and target
reports/biosample_set_1_info_index.txt:
	$(BASEXCMD) -c "open biosample_set_1 ; info index" > $@

# hardcoded db and target
reports/biosample_set_2_info_index.txt:
	$(BASEXCMD) -c "open biosample_set_2 ; info index" > $@

bio_project:
	rm -f target/bioproject.xml
	${BASEXCMD} -c 'drop db bioproject'
	rm -f target/bp_id_accession.tsv
	curl https://ftp.ncbi.nlm.nih.gov/bioproject/bioproject.xml --output target/bioproject.xml
	$(BASEXCMD) -c 'CREATE DB bioproject target/bioproject.xml'
	$(BASEXCMD)  queries/bp_id_accession.xq > target/bp_id_accession.tsv
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import target/bp_id_accession.tsv bp_id_accession" ""