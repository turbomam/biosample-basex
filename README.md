# biosample-basex
_Using XQueries in a BaseX database to convert NCBI's BioSample database from XML to SQLite._

Querying the native BioSample database requires familiarity with, and access to tools designed for XPath, XQuery or XSLT. The SQLite database generated by this software can be queried from Python programs or a multitude of commercial, open-source, CLI and GUI tools, using _the most common query language_. No citation provided :-)

## BioSample metadata background

When a scientist submits data (like taxonomic identification or gene expression) to NCBI, they are also required to submit metadata about the [BioSamples](https://www.ncbi.nlm.nih.gov/biosample/) from which that data was collected. 

NCBI uses the term **attribute** to describe certain named information about the BioSamples. Submitters can tag this information about their BioSamples with any attribute names they choose. The NCBI performs curation of the BioSamples, and attributes that appear to share the same meaning as controlled terms from standards like the [GSC's `MIxS`](https://gensc.org/mixs/) are given harmonized names.

These BioSample `attribute`s should not be confused with XML markup construct that is also called [`attribute`](https://en.wikipedia.org/wiki/XML#Key_terminology). In fact, the BioSample attributes are actually XML `element`s (from the path `BioSampleSet/BioSample/Attributes/Attribute`) although `@attribute_name` and `@harmonized_name` are XML `attribute`s.

There are several other paths with `element`s, and `attribute`s of elements that describe the BioSamples. For example, see the **Path Index** section of [reports/biosample_set_1_info_index.txt](reports/biosample_set_1_info_index.txt)

## BaseX database limits

As of early January, 2022, the number of XML nodes necessary to model the 22,786,924 BioSamples was 2,397,333,775. This repo uses the BaseX open-source XML database, which is feature rich and performs well. However, BaseX does have per-database [limits](https://docs.basex.org/wiki/Statistics), such as no more than 2,147,483,648 nodes per database. Therefore, NCBI's [biosample_set.xml.gz](https://ftp.ncbi.nlm.nih.gov/biosample/) is split into two chunks with `sed` and then loaded in two BaseX databases. Queries written in the `XQuery` language are then executed over the two databases, generating various `TSV` files.  


## SQLite output

After running the XQueries, the generated `TSV`s are loaded into a SQLite database. SQLite was selected because the entire, indexed and ready-to-use database can be shared as a single, compressible file and because of the plethora of compatible tools, which do not require setting up a persistent database server. Examples include Python's built-in [sqlite module](https://docs.python.org/3/library/sqlite3.html), the `sqlite` command line client (which can be downloaded from https://www.sqlite.org/download.html or installed with package managers that are included in many Unix-like operating systems), or with a graphical tool like [DBeaver](https://dbeaver.io/download/). 

### Tables in the SQLite database 

_Note: some column names like `id` and `temp` may be reserved words. These should be wrapped in double quotes when writing queries._

- all_attribs
    - All "attribute" elements from all BioSamples, whether they have a harmonized name or not, in a long format.
    - Pretty slow to query, despite indexing several columns.
    - `CREATE INDEX all_attribs_idx on all_attribs("harmonized_name", "raw_id", "attribute_name");`
    - Maybe the indexes weren't set up properly? (I haven't tried querying without indexes.)
    - 324,806,062 rows
    - columns (`TEXT` unless otherwise specified):
        - raw_id (`INTEGER`)
        - attribute_name
        - harmonized_name
        - value
- env_package_repair
    - Standardizes the user-submitted `env_package` values
    - From [env_package_repair_curated.tsv](env_package_repair_curated.tsv)
    - The `Makefile` has a step to create a `target/env_package_repair_new.tsv`. No tools are provided yet for automatically reconciling the new file with the previous curated file.
    - 99 rows
    - columns (`TEXT` unless otherwise specified):
        - env_package_raw
        - count (`INTEGER`)
        - env_package _(indexed)_
        - checklist_fragment
        - curation_confidence
        - notes
        - curation_complete
- harmonized_wide
    - Just the values of those attributes that have harmonized names, as `TEXT`, in wide format. Also includes the BioSample `raw_id`s, as `INTEGER`s.
    - 22,608,173 rows
    - 516 columns including `raw_id`
    - Provided with indices on `raw_id_idx` and `env_package`. More could be added for better queries at the cost of disk footprint.
- harmonized_wide_repaired
    - Exact same shape as `harmonized_wide`. Serves as a place to collect values that have gone though some cleanup/repair process. Currently `env_package` is the only column repaired by this repo, by way of the `env_package_repair` table.
    - Provided with an index on `raw_id_idx`
- non_attribute_metadata
    - Metadata about the BioSamples that doesn't come from "attribute" entities. External IDs and links have been simplified compared to previous versions. Among other things, `DOI`s have been omitted , since they are only available for ~ 400 out of the 20+ million BioSamples.
    - 24,580,658 rows. That's greater than the number of `harmonized_wide` rows as some BioSamples don't have any attributes with harmonized names.
    - columns (`TEXT` unless otherwise indicated):
        - id (Not native to the `biosample_set.xml` file. Built from the prefix "BIOSAMPLE:" and the `primary_id`)
        - accession
        - raw_id (`INTEGER`, _primary key_)
        - primary_id
        - sra_id
        - bp_id (while these are stored as `TEXT`, they are **numerical** BioProject IDs and should really be joined with the BioProject XML database to get BioProject accessions.)
        - model
        - package
        - package_name
        - status
        - status_date
        - taxonomy_id
        - taxonomy_name
        - title
        - paragraph

As of 2022-01-03
_The SQLite DBs contain minimal indices_
- biosample_basex.db.gz: 7.7 GB
- biosample_basex.db:   67.9 GB

## Usage

BaseX and SQLite can be installed with homebrew on Macs or `apt-get` on Ubuntu Linux machines. They're both open-source software. **SQLite3 3.32 or greater is required.**

Downloading the BaseX `.zip` archive makes it a little more straightforward to increase the amount of memory allocated by the launch scripts. For example, on a 32 GB machine, `basex/bin/basex` might look like this:

```bash
#!/usr/bin/env bash

# Path to this script
FILE="${BASH_SOURCE[0]}"
while [ -h "$FILE" ] ; do
  SRC="$(readlink "$FILE")"
  FILE="$( cd -P "$(dirname "$FILE")" && \
           cd -P "$(dirname "$SRC")" && pwd )/$(basename "$SRC")"
done
MAIN="$( cd -P "$(dirname "$FILE")/.." && pwd )"

# Core and library classes
CP=$MAIN/BaseX.jar:$MAIN/lib/custom/*:$MAIN/lib/*:$CLASSPATH

# Options for virtual machine (can be extended by global options)
BASEX_JVM="-Xmx24g $BASEX_JVM"

# Run code
exec java -cp "$CP" $BASEX_JVM org.basex.BaseX "$@"
```

https://docs.basex.org/wiki/Main_Page

https://basex.org/download/


## NERSC cori specific notes

`make all` takes roughly 8 hours.

- `cd /global/cfs/cdirs/m3513/endurable/biosample`
- `git clone git@github.com:turbomam/biosample-basex.git` 
- `wget` the latest BaseX zip archive
    - 2022-01-02: `wget https://files.basex.org/releases/9.6.4/BaseX964.zip`
- `unzip BaseX964.zip`
- increase the Java memory allocation in `basex/bin/basex`
    - `BASEX_JVM="-Xmx96g $BASEX_JVM"`
    - That may be more than necessary. Seems to run OK on an Intel MacBook Pro with 24 GB allocated.
- `cp biosample-basex/template.env biosample-basex/.env`
- edit `biosample-basex/.env`
    - `BASEXCMD = ../basex/bin/basex`
    - The value for `del_from` should be roughly half the number of BioSamples. The suggested value of 12500001 should be reasonable but could be revised after downloading and unpacking the BioSample XML file. Run something like `tail -n 50 target` at the shell prompt, note the `id` attribute of the last `<BioSample>`, and set `del_from` to an integer close to one half of that last `id` value. 
- Start a session manager like `screen`. If you get disconnected, it may be tricking to log back into the same cori node because of load balancing, but scripts started before the disconnection should run to completion. It doesn't hurt to force your client computer to stay awake with something like `caffeine`.
- `module load python`
    - On cori, this makes common Python packages like `pandas` available. On other systems, users should create a `venv` virtual environment, enter it, and run `pip install -r requirments.txt`
- cd `biosample-basex/`
- `make all`

After running `make final_sqlite_gz_dest`, the SQLite will be available at https://portal.nersc.gov/project/m3513/biosample/
