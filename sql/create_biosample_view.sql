CREATE VIEW biosample_basex_merged
AS
SELECT nam.raw_id      as nam_raw_id,
       nam.id,
       nam.accession,
       nam.primary_id,
       nam.sra_id,
       nam.bp_id,
       nam.model,
       nam.package,
       nam.package_name,
       nam.status,
       nam.status_date,
       nam.taxonomy_id,
       nam.taxonomy_name,
       nam.title,
       nam.samp_name,
       nam.paragraph,
       bia.bp_acc,
       hwr.env_package as repaired_env_package,
       hw.*
FROM non_attribute_metadata nam
         left JOIN harmonized_wide hw on nam.raw_id = hw.raw_id
         left join bp_id_accession bia on nam.bp_id = bia.bp_id
         left join harmonized_wide_repaired hwr on nam.raw_id = hwr.raw_id;