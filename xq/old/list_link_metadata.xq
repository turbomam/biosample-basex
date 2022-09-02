declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

for $link in doc(
  'biosample_set'
)/BioSampleSet/BioSample/Links/Link

let $id := data($link/../../@id)
let $ltype :=  data($link/@type)
let $llab :=  data($link/@label)
let $ltarg :=  data($link/@target)

return 

<csv><record> 



<type>{
    $ltype
}</type>

<target>{
    $ltarg
}</target>

</record></csv>

(:
<raw_id>{
    $id
}</raw_id>

 <label>{
    $llab
}</label>
 :)