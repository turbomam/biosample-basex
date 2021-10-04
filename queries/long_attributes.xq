declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";


for $bs in doc(
  'biosample_set'
)/BioSampleSet/BioSample

let $bs_id_val := data(
  $bs/@id
)

(: 
let $env_package_attrib := data(
  $bs/Attributes/Attribute[@harmonized_name='env_package']
)

where $env_package_attrib != "" and $env_package_attrib != "missing"
:)


(: make [@harmonized_name] optional?
ie allow the huge number of non-harmonized attributes?
or do it on a one-by-one basic in the wide query? :)

for $uhn_val in distinct-values(
  $bs/Attributes/Attribute[@harmonized_name]/@harmonized_name
)
let $x := data(
  $bs/Attributes/Attribute[@harmonized_name=$uhn_val]
)

(: lower-case? :)

let $potentially_shared := fn:normalize-space(
  string-join(
    sort(
      distinct-values(
        $x
      )
    ),'|||'
  )
)

return 

<csv><record> 
<id>{
  $bs_id_val
}</id>
<attribute>{
  $uhn_val
}</attribute>
<value>{
  $potentially_shared
}</value>
</record></csv>

