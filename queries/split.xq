for $bs in doc('target/biosample_set_under_101.xml')/BioSampleSet/BioSample let $id := data($bs/@id) where $id < 11 return $bs
