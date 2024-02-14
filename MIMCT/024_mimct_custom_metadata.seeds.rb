puts 'Seeded T5.4 Clinical Trials Metadata (MIMCT) V0.5'

###############################################################################
# Initialisation of aliases for common sample attributes types, for easier use
###############################################################################

string_type = SampleAttributeType.find_or_initialize_by(title: 'String')
string_type.update(base_type: Seek::Samples::BaseType::STRING)

text_type = SampleAttributeType.find_or_initialize_by(title: 'Text')
text_type.update(base_type: Seek::Samples::BaseType::TEXT)

date_type = SampleAttributeType.find_or_initialize_by(title: 'Date')
date_type.update(base_type: Seek::Samples::BaseType::DATE)

date_time_type = SampleAttributeType.find_or_initialize_by(title: 'Date time')
date_time_type.update(base_type: Seek::Samples::BaseType::DATE_TIME)

int_type = SampleAttributeType.find_or_initialize_by(title: 'Integer')
int_type.update(base_type: Seek::Samples::BaseType::INTEGER, placeholder: '1')

float_type = SampleAttributeType.find_or_initialize_by(title: 'Real number')
float_type.update(base_type: Seek::Samples::BaseType::FLOAT, placeholder: '0.5')

boolean_type = SampleAttributeType.find_or_initialize_by(title: 'Boolean')
boolean_type.update(base_type: Seek::Samples::BaseType::BOOLEAN)

cv_type = SampleAttributeType.find_or_initialize_by(title: 'Controlled Vocabulary')
cv_type.update(base_type: Seek::Samples::BaseType::CV)

cv_type_list = SampleAttributeType.find_or_initialize_by(title: 'Controlled Vocabulary List')
cv_type_list.update(base_type: Seek::Samples::BaseType::CV_LIST)

linked_extended_metadata_type = SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata')
linked_extended_metadata_type.update(base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA)

linked_extended_metadata_type_list = SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata (multiple)')
linked_extended_metadata_type_list.update(base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA_MULTI)

# helper to create sample controlled vocab
def create_sample_controlled_vocab_terms_attributes(array)
  attributes = []
  array.each do |type|
    attributes << { label: type }
  end
  attributes
end

disable_authorization_checks do

###############################################################################
# Definition of the sample controlled vocabularies
###############################################################################

  # study type
  study_type_cv = SampleControlledVocab.where(title: 'Study Type').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Interventional', 'Observational', 'Feasibility'])
  )

  # study status
  study_status_cv = SampleControlledVocab.where(title: 'Study Status').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Active (recruting)', 'Active (not recruting)', 'Completed'])
  )

  # study status
  study_dmp_cv = SampleControlledVocab.where(title: 'Study DMP').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Yes', 'No', 'On request'])
  )

###############################################################################
# Definition of the extended metadata types
# (helpers used later for nesting in extendeded metadata schemas)
###############################################################################

  unless ExtendedMetadataType.where(title:'study_condition', supported_type:'ExtendedMetadata').any?
    emt = ExtendedMetadataType.new(title: 'study_condition', supported_type:'ExtendedMetadata')
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'ICD-10 code', sample_attribute_type: SampleAttributeType.where(title:'String').first)
    emt.save!
  end

###############################################################################
# Definition of the Custom Metadata types
# (helper used later in constructing the extended metadata schema)
###############################################################################

  # Helper
  def create_custom_metadata_attribute(title:, required:, sample_attribute_type:, sample_controlled_vocab: nil)
    CustomMetadataAttribute.where(title).create!(title: title, required: required,
                                                 sample_attribute_type: sample_attribute_type,
                                                 sample_controlled_vocab: sample_controlled_vocab)
  end


###############################################################################
  # ISA Study
###############################################################################

  CustomMetadataType.where(title: 'MIMCT Metadata V0.3 for object type Study', supported_type: 'Study').first_or_create!(
    title: 'MIMCT Metadata V0.5 for object type Study', supported_type: 'Study',
    custom_metadata_attributes: [
      create_custom_metadata_attribute(title: 'study_acronym',      required: false, sample_attribute_type: string_type, description: 'Short abbreviation referencing the study', label: 'Study Acronym'),
      create_custom_metadata_attribute(title: 'study_identifier',   required: false, sample_attribute_type: string_type, description: 'Identifier from a clinical trial registry', label: 'Study Identifier'),
      create_custom_metadata_attribute(title: 'study_start_date',   required: false, sample_attribute_type: date_type, description: 'Actual or planned, if applicable', label: 'Study Start Date'),
      create_custom_metadata_attribute(title: 'study_end_date',     required: false, sample_attribute_type: date_type, description: 'Actual or planned, if applicable', label: 'Study End Date'),
      create_custom_metadata_attribute(title: 'study_homepage',     required: false, sample_attribute_type: link_type, description: 'Specific website for study content', label: 'Study Homepage'),
      create_custom_metadata_attribute(title: 'study_pi',           required: false, sample_attribute_type: string_type, description: 'Please enter only one name', label: 'Principle Investigator'),
      create_custom_metadata_attribute(title: 'study_sponsor',      required: false, sample_attribute_type: string_type, description: 'Please enter only one name', label: 'Sponsor'),
      create_custom_metadata_attribute(title: 'study_type',         required: false, sample_attribute_type: cv_type, sample_controlled_vocab: study_type_cv, description: '', label: 'Study Type'),
      create_custom_metadata_attribute(title: 'study_condition',    required: false, sample_attribute_type: SampleAttributeType.where(title:'Linked Extended Metadata').first, linked_extended_metadata_type: ExtendedMetadataType.where(title:'study_condition', supported_type:'ExtendedMetadata').first, description: '', label: 'Health conditions studied'),
      create_custom_metadata_attribute(title: 'study_sample_size'   required: false, sample_attribute_type: int_type, description: 'Actual value for completed studies, planned for active studies', label: 'Number of subjects enrolled'),
      create_custom_metadata_attribute(title: 'study_status',       required: false, sample_attribute_type: cv_type, sample_controlled_vocab: study_status_cv, description: '', label: 'Study Status'),
      create_custom_metadata_attribute(title: 'study_sites_number', required: false, sample_attribute_type: int_type, description: 'Actual value for completed studies, planned for active studies', label: 'Number of sites'),
      create_custom_metadata_attribute(title: 'study_dmp',          required: false, sample_attribute_type: cv_type, sample_controlled_vocab: study_dmp_cv, description: 'Plan for data sharing in compliance with subject's consent', label: 'Data Management Plan for data sharing?')
    ]
  )

end

