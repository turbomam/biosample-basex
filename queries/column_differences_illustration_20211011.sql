--- NULLs indicate samples for which there are no harmonized namae attributes? (left merge)
--- no "attribute" column any more. Was always empty in harmonized_table.db
--- note quoting of column anmes that are reserved in some SQL dialects
select
	"id",
	raw_id, --- good for indexing
	--- was accession_biosample_id
	primary_id,
	accession,
	xref_ids,
	--- was xref
	entrez_links,
	--- was entrez_label, entrez_target and entrez_value
	sra_id,
	status,
	status_when,
	--- was status_date ("when" is the XML attribute used by NCBI)
	"index",
	--- leftover in catted_wide_harmonized_attributes from some pandas step (to_csv lacking index=False?)
	---
	--- emp500*: selected these non harmonized attributes in order to find emp500 samples. remove moving pictures samples?
	emp500_principal_investigator,
	emp500_study_id,
	emp500_title,
	--- sars_cov_2: new harmonized attributes since last harmonized_table.db generation
	date_of_sars_cov_2_vaccination,
	prior_sars_cov_2_vaccination,
	--- wasterwater: new harmonized attributes since last harmonized_table.db generation
	purpose_of_ww_sampling,
	ww_processing_protocol,
	ww_sample_site,
	ww_surv_jurisdiction,
	ww_surv_system_sample_id
from
	biosample_basex_merged bbm ;