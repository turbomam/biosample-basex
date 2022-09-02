for $bs in doc(
  'biosample_set'
)/BioSampleSet/BioSample

where $bs/Description/Organism/@taxonomy_id != "9606"

return $bs
