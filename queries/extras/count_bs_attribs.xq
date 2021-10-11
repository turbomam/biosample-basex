declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";


for $bsattrib in doc(
  'biosample_set'
)/BioSampleSet/BioSample/@*
let $attribname :=  name(
  $bsattrib
)
group by $attribname

return <csv><record>
<bs_attrib>{
  $attribname
}</bs_attrib>
<count>{
  count(
    $bsattrib
  )
}</count>
</record></csv>
