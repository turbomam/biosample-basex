.PHONY: biosample-basex
.PHONY: count-biosamples

# be careful about using the basex gui and cli at the same time
# (memory-wise, that is)

# work on file and variable naming conventions
# capitalization
# count X by Y
# use CSV serializer wherever possible, not string concatenation
# make sure that the same dataset is being used in all queries

# be consistent about identifying samples with accession or primary ID

# use curl or wget?
# actually getting an error using wget from my LBL MBP!
# 2021-06-15: 1.3 GB
# roughly 1 minute
downloads/biosample_set.xml.gz:
	# wget ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz
	curl ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz --output $@

# 2021-06-15: 44 GB
# 731549545 text LINES (not entity count)
# roughly 1 minute
target/biosample_set.xml: downloads/biosample_set.xml.gz
	gunzip -c $< > $@

# ~ 40 minutes @ Xmx  = 24 GB RAM
# ~ 45 GB
# not certain that all of the most impactful indexes are being built
# on MacOS, the database will be created in ~/basex/data by default
biosample-basex: target/biosample_set.xml
	basex -c 'CREATE DB biosample_set target/biosample_set.xml'

count-biosamples:
	date ; time basex queries/count_biosamples.xq


# is there a pattern for generalizing these queries?

# BioSampleSet elements only have BioSample elements
target/count_BioSampleSet_elements.tsv:
	basex queries/count_BioSampleSet_elements.xq | tee $@

target/count_BioSample_elements.tsv:
	basex queries/count_BioSample_elements.xq | tee $@

# Id elements have no child elements
target/count_BioSample_Ids_elements.tsv:
	basex queries/count_BioSample_Ids_elements.xq | tee $@

# Do Id elements have attributes (from an XML syntax perspective?)
target/count_id_attribs.tsv:
	basex queries/count_id_attribs.xq | tee $@

# What values does the db attribute take?
target/count_biosamples_by_iddb.tsv:
	basex queries/count_biosamples_by_iddb.xq > $@ && head $@

# add more, like bs accession, is primary, db label
target/list_iddb_idval_by_primary.tsv:
	basex queries/list_iddb_idval_by_primary.xq > $@ && head $@

# what are the attributes of BioSamples?
target/count_bs_attribs.tsv:
	basex queries/count_bs_attribs.xq > $@ && head $@

#data(BioSampleSet/BioSample/Models/Model) have up to 2 models per biosample
target/count_model_values.tsv:
	basex queries/count_model_values.xq > $@ && head $@
target/list_biosample_model_combos.tsv:
	basex queries/list_biosample_model_combos.xq > $@ && head $@
target/count_models_by_biosample.tsv:
	basex queries/count_models_by_biosample.xq > $@ && head $@

# https://www.ncbi.nlm.nih.gov/books/NBK169436/ :
# In addition to BioSample type (called Model in the schema) and attributes,
# each BioSample record also contains:
target/list_biosamples_packages.tsv:
	basex queries/list_biosamples_packages.xq > $@ && head $@
# package has data and display name

# 12 minutes
target/biosample_attribute_value_xq.tsv:
	date && time ( basex queries/biosample_attribute_value_xq.xq > $@ ) && head $@

# 15 minutes
# this is currently a SUBSET of the columns in the harmonized_table.db SQLite database
target/biosample_tabular.tsv:
	date ; time basex queries/biosample_tabular.xq > $@ && head $@