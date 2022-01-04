declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

for $archid in doc(
  'bioproject'
)/PackageSet/Package/Project/Project/ProjectID/ArchiveID

let $bp_id := data(
  $archid/@id
)

let $bp_acc := data(
  $archid/@accession
)

return 

<csv><record> 

<bp_id>{
    $bp_id
}</bp_id>

<bp_acc>{
$bp_acc
}</bp_acc>


</record></csv>