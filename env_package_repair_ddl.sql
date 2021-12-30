-- env_package_repair definition

CREATE TABLE env_package_repair(
  "env_package_raw" TEXT,
  "count" INTEGER,
  "env_package" TEXT,
  "checklist_fragment" TEXT,
  "curation_confidence" TEXT,
  "notes" TEXT,
  "curation_complete" TEXT
);

CREATE  INDEX env_package_repair_epr_idx ON
env_package_repair(env_package_raw);