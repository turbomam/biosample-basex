declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

let $delim := "|||"


for $attrib in doc(
  'biosample_set'
)/BioSampleSet/BioSample/Attributes/Attribute

let $accession := data(
  $attrib/../../@accession
)

let $bs := $attrib/../..

let $primary_id := fn:normalize-space(
  string-join(
    data(
      $bs/Ids/Id[@is_primary="1"]
    ),$delim
  )
)

(: string join without distinct/unique prob causes dupes :)
let $curie_id := fn:normalize-space(
concat(
      "BIOSAMPLE:",$primary_id
  )
)

let $an := data(
  $attrib/@attribute_name
)
let $n := data(
  $attrib/@harmonized_name
)

let $v := data(
  $attrib
)

return 

<csv><record> 

<id>{
  $curie_id
}</id>

<attribute_name>{
  $an
}</attribute_name>
<harmonized_name>{
  $an
}</harmonized_name>

<value>{
  $v
}</value>

</record></csv>

(: <accession>{
  $accession
}</accession> :)