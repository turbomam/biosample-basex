# biosample-basex
Using XQueries in a BaseX database to convert NCBI's BioSample database from XML to SQLite.

**Required SQLite3 3.36**

NCBI 

Name             Resources  Size         Input Path                                                                                           
--------------------------------------------------------------------------------------------------------------------------------------------
biosample_set_1  1          32517967506  /global/cfs/cdirs/m3513/endurable/biosample/biosample-basex/target/biosample_set_under_12500001.xml  
biosample_set_2  1          30367728281  /global/cfs/cdirs/m3513/endurable/biosample/biosample-basex/target/biosample_set_over_12500001.xml   


Specificlly, the result is a database with the following tables:
- all_attribs
- env_package_repair
- harmonized_wide
- harmonized_wide_repaired
- non_attribute_metadata

As of 2022-01-03
SQLite DBs contain minimal indices
biosample_basex.db.gz: 7.7 GB
biosample_basex.db:   67.9 GB

BaseX can be installed with homebrew on Macs or `apt-get` on Ubuntu Linux machines. It's open-source software.

Downloading the `.zip` archive makes it a little more straightforward to increase the amount of memory allocated by the launch scripts. For example, on a 32 GB machine, `basex/bin/basex` might look like this:

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
- Start a session manager like `screen`. If you get disconnected, it may be tricking to log back inot the same cori node because of load balancing, but scripts started before the disconnection should run to completion. It doesn't hurt to force your client computer to stay awake with something like `caffeine`.
- `module load python`
    - On cori, this makes common Python paackages like `pandas` available. On other systems, users should create a `venv` virtual environment, enter it, and run `pip install -r requirments.txt`
- cd `biosample-basex/`
- `make all`

----

results can be found at https://portal.nersc.gov/project/m3513/biosample/
