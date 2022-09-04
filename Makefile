# todo template.env and .env need more documentation

# todo more indexing and joining esp bioproject and repaired env pack

# https://stackoverflow.com/questions/6824717/sqlite-how-do-you-join-tables-from-different-databases

## uses the default BaseX data directory for whichever binary was selected
## remember that we will be looping over all databases for some queries

## work on file and variable naming conventions
## capitalization
## count X by Y

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

SPLITDIR=target/splitted

.PHONY:  all \
basex_load \
bio_project \
biosample-basex \
check_env \
clean \
create_view \
final_sqlite_gz_dest \
ha_highlights_reports \
remind \
split_biosample_set \
sqlite_reports

remind:
	@echo
	@echo "CHECK THE RAM AVAILABLE ON YOUR SYSTEM, AND THE ALLOCATION TO BASEX"
	@echo "DON'T FORGET 'module load python/3.9-anaconda-2021.11' FOR CORI OR 'source venv/bin/activate' FOR OTHER SYSTEMS"
	@echo "DON'T FORGET 'screen' FOR REMOTE SYSTEMS INCLUDING CORI"
	@echo
	-pip list | grep pandas
	-screen -ls

split_biosample_set:
	python util/bioasample_set_splitter.py \
		--input_file_name target/biosample_set.xml \
		--output_dir=$(SPLITDIR) \
		--biosamples_per_file ${BIOSAMPLES_PER_SPLIT} \
		--last_biosample ${BIOSAMPLE_FOR_LAST_SPLIT}

$(SPLITDIR)/%.loaded_not_created: $(SPLITDIR)/%.xml
	$(BASEXCMD) -c 'CREATE DB $(basename $(notdir $<)) $<'



all: fetch_decompress splitting do_basex_load post_load pivot post_pivot_etc



fetch_decompress: remind check_env squeaky_clean target/biosample_set.xml
	rm -f target/bioproject.xml
	rm -f target/bp_id_accession.tsv
	- ${BASEXCMD} -c 'drop db bioproject'
	curl ${BIOPROJECT_XML_URL} --output downloads/bioproject.xml

splitting: clean split_biosample_set

SPLITLIST = $(wildcard $(SPLITDIR)/*.xml)
BASEX_LOAD = $(subst xml,loaded_not_created,$(SPLITLIST))

do_basex_load: $(BASEX_LOAD)
	@echo "echoing the files to load"
	echo $(BASEX_LOAD)

post_load: reports/basex_list.txt reports/biosample_set_from_0_info_db.txt reports/biosample_set_from_0_info_index.txt \
target/biosample_basex.db

do_pivot: pivot

post_pivot_etc: post_pivot bio_project target/env_package_repair_new.tsv create_view \
target/biosample_basex.db.gz final_sqlite_gz_dest

# todo omitting sqlite_reports because it assumes the presence of columns that might be absent due to partial load

# ha_highlights_reports fails on cori
#   value_counts() got an unexpected keyword argument 'dropna'
sqlite_reports: reports/grow_facil_pattern.tsv reports/sam_coll_meth_pattern.tsv ha_highlights_reports


squeaky_clean: clean
	rm -f downloads/*.gz
	rm -f downloads/*.xml
	rm -rf target/biosample_set.xml

clean:
	${BASEXCMD} -c 'drop db biosample_set_*'
	rm -f reports/*.tsv
	rm -f reports/*.txt
	rm -f target/*.db
	rm -f target/*.tsv
	rm -f target/splitted/*.xml
	mkdir -p target/splitted


bio_project:
	$(BASEXCMD) -c 'CREATE DB bioproject downloads/bioproject.xml'
	$(BASEXCMD)  xq/bp_id_accession.xq > target/bp_id_accession.tsv
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import target/bp_id_accession.tsv bp_id_accession" ""

check_env:
	echo ${BIOSAMPLE_SET_XML_URL}
	echo ${BASEXCMD}
	echo ${FINAL_SQLITE_GZ_DEST}

create_view:
	sqlite3 target/biosample_basex.db < sql/create_biosample_view.sql


# 20211004: 1.5 GB
# roughly 1 minute
downloads/biosample_set.xml.gz:
	curl ${BIOSAMPLE_SET_XML_URL} --output $@

# on cori, /global/cfs/cdirs/m3513/www/biosample is exposed at https://portal.nersc.gov/project/m3513/biosample
final_sqlite_gz_dest: target/biosample_basex.db.gz
	cp $< ${FINAL_SQLITE_GZ_DEST}
	chmod 777 ${FINAL_SQLITE_GZ_DEST}

reports/basex_list.txt:
	$(BASEXCMD) -c "list" > $@

# hardcoded db and target
# could parameterize this too, but do we really want dozens of reports?
reports/biosample_set_from_0_info_db.txt:
	$(BASEXCMD) -c "open biosample_set_from_0; info db" > $@

# hardcoded db and target
reports/biosample_set_from_0_info_index.txt:
	$(BASEXCMD) -c "open biosample_set_from_0; info index" > $@

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
	zip -r reports/sample_name_by_env_package.tsv.zip reports/sample_name_by_env_package.tsv
	rm -f reports/sample_name_by_env_package.tsv


target/biosample_basex.db:
	# time these and record expected execution times?
	sqlite3 target/biosample_basex.db < sql/all_attribs.sql
	sqlite3 target/biosample_basex.db < sql/non_attribute_metadata.sql
	$(BASEXCMD) xq/all_biosample_attributes_values_by_raw_id.xq > target/all_biosample_attributes_values_by_raw_id.tsv
	$(BASEXCMD) xq/biosample_non_attribute_metadata_wide.xq > target/biosample_non_attribute_metadata_wide.tsv
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import --skip 1 target/all_biosample_attributes_values_by_raw_id.tsv all_attribs" ""
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import --skip 1 target/biosample_non_attribute_metadata_wide.tsv non_attribute_metadata" ""

pivot:
	python3 util/pivot_harmonizeds.py

post_pivot:
	sqlite3 target/biosample_basex.db < sql/harmonized_wide_raw_id_idx.sql
	sqlite3 target/biosample_basex.db < sql/harmonized_wide_env_package_idx.sql
	sqlite3 target/biosample_basex.db < sql/env_package_repair_ddl.sql
	sqlite3 target/biosample_basex.db \
		".mode tabs" ".import --skip 1 data/env_package_repair_curated.tsv env_package_repair" ""
	sqlite3 target/biosample_basex.db < sql/harmonized_wide_repaired_ddl.sql
	sqlite3 target/biosample_basex.db < sql/indexing.sql

# depends on target/biosample_basex.db
#   but want to be careful about adding duplicate rows to SQLite
#   or nuking any rows
target/biosample_basex.db.gz:
	gzip -c target/biosample_basex.db > $@
	chmod 777 $@

# 2021-06-15: 51 GB
# roughly 2 minutes
target/biosample_set.xml: downloads/biosample_set.xml.gz
	gunzip -c $< > $@

target/env_package_repair_new.tsv: target/biosample_basex.db
	sqlite3 -readonly -csv -header -separator $$'\t' $< < sql/env_package_repair.sql > $@