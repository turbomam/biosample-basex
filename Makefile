.PHONY: biosample-basex count-biosamples

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
	time basex queries/count_biosamples.xq

