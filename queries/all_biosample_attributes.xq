declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";


for $attrib in doc(
  'biosample_set'
)/BioSampleSet/BioSample/Attributes/Attribute

let $accession := data(
  $attrib/../../@accession
)

let $an := data(
  $attrib/@attribute_name
)
let $n := data(
  $attrib/@harmonized_name
)

return 

<csv><record> 
<accession>{
  $accession
}</accession>
<attribute_name>{
  $an
}</attribute_name>
<harmonized_name>{
  $an
}</harmonized_name>
</record></csv>