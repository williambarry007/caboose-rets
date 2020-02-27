
class CabooseRets::Office < ActiveRecord::Base
  self.table_name = "rets_offices"
  
  has_one :meta, :primary_key => 'matrix_unique_id', :foreign_key => 'matrix_unique_id'  
  # attr_accessible :id, :name, :lo_mls_id, :matrix_unique_id
  
  def image
    return nil if self.meta.nil?
    return meta.image
  end
  
  def parse(data)
        self.lo_addr1                     = data['OfficeAddress1']
        self.lo_addr2                     = data['OfficeAddress2']
        self.lo_city                      = data['OfficeCity']
        self.lo_email                     = data['OfficeEmail']
        self.lo_fax_phone                 = data['OfficeFax']
        self.lo_mail_addr                 = data['OfficeAddress1']
     #   self.lo_mail_care_of              = data['MailCareOf']
        self.lo_mail_city                 = data['OfficeCity']
        self.lo_mail_postal_code          = data['OfficePostalCode']
        self.lo_mail_postal_code_plus4    = data['OfficePostalCodePlus4']
        self.lo_mail_state_or_province    = data['OfficeStateOrProvince']
        self.matrix_unique_id             = data['OfficeKey']
        self.lo_matrix_modified_dt        = data['ModificationTimestamp']
        self.lo_mls                       = 'West Alabama Multiple Listing Service'
        self.lo_mls_id                    = data['OfficeMlsId']
        self.lo_office_contact_mui        = data['OfficeManagerMlsId']
        self.lo_office_contact_mls_id     = data['OfficeManagerMlsId']        
        self.lo_office_long_name          = data['OfficeName']
        self.lo_office_name               = data['OfficeName']
        self.lo_phone                     = data['OfficePhone']
    #    self.lo_photo_count               = data['PhotoCount']
    #    self.photo_modification_timestamp = data['PhotoModificationTimestamp']        
        self.state                        = data['OfficeStateOrProvince']
        self.street_address               = data['OfficeAddress1']
        self.street_city                  = data['OfficeCity']
        self.street_postal_code           = data['OfficePostalCode']
        self.street_postal_code_plus4     = data['OfficePostalCodePlus4']
        self.street_state_or_province     = data['OfficeStateOrProvince']
  #      self.web_facebook                 = data['WebFacebook']
  #      self.web_linked_in                = data['WebLinkedIn']
  #      self.web_page_address             = data['WebPageAddress']
  #      self.web_twitter                  = data['WebTwitter']
        self.zip                          = data['OfficePostalCode'] 
  end
end
