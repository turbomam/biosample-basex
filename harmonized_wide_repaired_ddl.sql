CREATE TABLE harmonized_wide_repaired AS
SELECT
	*
FROM
	harmonized_wide
WHERE
	0;

INSERT
	INTO
	harmonized_wide_repaired (raw_id)
SELECT
	raw_id
FROM
	harmonized_wide ;


CREATE UNIQUE INDEX harmonized_wide_repaired_raw_id_idx ON
harmonized_wide_repaired(raw_id);

UPDATE
	harmonized_wide_repaired
SET
	env_package = epr.env_package
from
	env_package_repair epr
JOIN harmonized_wide hw ON
	hw.env_package = epr.env_package_raw
where
	harmonized_wide_repaired.raw_id = hw.raw_id;
