(: much slower than using temporary TSV, ast least as is :)

sql:init(
  "org.sqlite.JDBC"
),
let $conn := sql:connect(
  "jdbc:sqlite:database.db"
)

for $db in db:list()
  let $coll := db:open(
  $db
)
  where fn:starts-with(
  $db, "biosample_set_"
)

for $attrib in $coll/BioSampleSet/BioSample/Attributes/Attribute

let $id_val := data(
  $attrib/../../@id
)
let $attrib_name := data(
  $attrib/@attribute_name
)
let $hn := data(
  $attrib/@harmonized_name
)
let $attrib_val := data(
  $attrib
)

let $replaced := replace($attrib_val, "'", "''")


(: what if the values have quotation marks in them? :)
let $q := "insert into all_attribs values (" || $id_val || ", '" || $attrib_name || "', '" || $hn || "', '" || $replaced || "')"

(: return $q :)
  
return sql:execute(
  $conn, $q
)
