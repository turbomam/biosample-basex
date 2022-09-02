select
	env_package as env_package_raw,
	count(1) as count,
	"" as env_package,
	"" as checklist_fragment,
	"" as curation_confidence,
	"" as notes,
	"" as curation_complete
from
	harmonized_wide hw
group by
	env_package
order by
	count(1) desc ;
