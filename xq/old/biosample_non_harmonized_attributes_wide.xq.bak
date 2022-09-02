declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

(: see https://github.com/turbomam/biosample-basex/issues/8 :)

let $delim := "|||"

for $bs in doc(
  'biosample_set'
)/BioSampleSet/BioSample

let $accession :=  fn:normalize-space(
  string-join(
    data(
      $bs/@accession
    ),$delim
  )
)


let $id := fn:normalize-space(
  string-join(
    data(
      $bs/@id
    ),$delim
  )
)

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

(: let $ xref := fn:normalize-space(
  string-join(
    $bs/Ids/Id/concat(
      @db,':',.
    ),$delim
  )
) :)


let $sraid :=  fn:normalize-space(
  string-join(
    data(
      $bs/Ids/Id[@db="SRA"]
    ),$delim
  )
)

(: let $dna_source := fn:normalize-space(
  string-join(
    data(
      $bs/Links/Link[@type="url" and @label="DNA Source"]
    ),$delim
  )
)
let $doi := fn:normalize-space(
  string-join(
    data(
      $bs/Links/Link[@label="DOI"]
    ),$delim
  )
)

let $entrez_link := $bs/Links/Link[@type="entrez"] :)

let $bp_link := $bs/Links/Link[@type='entrez' and @target='bioproject']

let $bp_ids := fn:normalize-space(
  string-join($bp_link,$delim))


(: let $entrez_links := fn:normalize-space(
  string-join(
    $entrez_link/concat(
      @target,':',@label,":",.
    ),$delim
  )
) :)

let $model := fn:normalize-space(
  string-join(
    data(
      $bs/Models/Model
    ),$delim
  )
)
let $package := fn:normalize-space(
  string-join(
    data(
      $bs/Package
    ),$delim
  )
)
let $package_display_name := fn:normalize-space(
  string-join(
    data(
      $bs/Package/@display_name
    ),$delim
  )
)
let $paragraph := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Comment/Paragraph
    ),$delim
  )
)

let $status := fn:normalize-space(
  string-join(
    data(
      $bs/Status/@status
    ),$delim
  )
)

let $status_date := fn:normalize-space(
  string-join(
    data(
      $bs/Status/@when
    ),$delim
  )
)

let $taxonomy_id := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Organism/@taxonomy_id
    ),$delim
  )
)
let $taxonomy_name := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Organism/@taxonomy_name
    ),$delim
  )
)
let $title := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Title
    ),$delim
  )
)


(: let $emp500_principal_investigator := fn:normalize-space(
  string-join(
    data(
      $bs/Attributes/Attribute[@attribute_name='emp500_principal_investigator']
    ),$delim
  )
)

let $emp500_study_id := fn:normalize-space(
  string-join(
    data(
      $bs/Attributes/Attribute[@attribute_name='emp500_study_id']
    ),$delim
  )
)

let $emp500_title := fn:normalize-space(
  string-join(
    data(
      $bs/Attributes/Attribute[@attribute_name='emp500_title']
    ),$delim
  )
) :)

return

<result><csv>


<id>{
  $curie_id
}
</id>

<accession>{
  $accession
}
</accession>

<raw_id>{
  $id
}
</raw_id>

<primary_id>{
  $primary_id
}</primary_id>

<sra_id>{
  $sraid
}</sra_id>


<bp_id>{
  $bp_ids
}</bp_id>


<model>{
  $model
}</model>

<package>{
  $package
}</package>
<package_name>{
  $package_display_name
}</package_name>

<status>{
  $status
}</status>

<status_date>{
  $status_date
}</status_date>

<taxonomy_id>{
  $taxonomy_id
}</taxonomy_id>
<taxonomy_name>{
  $taxonomy_name
}</taxonomy_name>


<title>{
  $title
}</title>

<paragraph>{
  $paragraph
}</paragraph>


</csv></result>

(:

<doi>{
  $doi
}</doi>

<xref>{
  $xref
}</xref>

<entrez_links>
{
  $entrez_links
}
</entrez_links>

<dna_source>{
  $dna_source
}</dna_source>

<emp500_principal_investigator>
{$emp500_principal_investigator}
</emp500_principal_investigator>

<emp500_study_id>
{$emp500_study_id}
</emp500_study_id>

<emp500_title>
{$emp500_title}
</emp500_title>

:)

