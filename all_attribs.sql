-- all_attribs definition

CREATE TABLE all_attribs(
  "raw_id" INTEGER,
  "attribute_name" TEXT,
  "harmonized_name" TEXT,
  "value" TEXT
);

CREATE INDEX all_attribs_idx on all_attribs("harmonized_name", "raw_id", "attribute_name");