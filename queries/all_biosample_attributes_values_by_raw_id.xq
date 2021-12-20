declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

for $attrib in doc(
  'biosample_set'
)/BioSampleSet/BioSample/Attributes/Attribute

let $id_val := data($attrib/../../@id)
let $attrib_name := data($attrib/@attribute_name)
let $hn := data($attrib/@harmonized_name)
let $attrib_val := data($attrib)

return


<csv><record> 

<raw_id>{
    $id_val
}</raw_id>

<attribute_name>{
$attrib_name
}</attribute_name>

<harmonized_name>{
$hn
}</harmonized_name>

<value>{
$attrib_val
}</value>

</record></csv>