
class CabooseRets::Office < ActiveRecord::Base
  self.table_name = "rets_offices"
  
  has_one :meta, :primary_key => 'matrix_unique_id', :foreign_key => 'matrix_unique_id'  
  attr_accessible :id, :name, :lo_mls_id, :matrix_unique_id
  
  def image
    return nil if self.meta.nil?
    return meta.image
  end
  
  def parse(data)
        self.lo_addr1                     = data['Addr1']
        self.lo_addr2                     = data['Addr2']
        self.lo_city                      = data['City']
        self.lo_email                     = data['Email']
        self.lo_fax_phone                 = data['FaxPhone']
        self.lo_mail_addr                 = data['MailAddr']
        self.lo_mail_care_of              = data['MailCareOf']
        self.lo_mail_city                 = data['MailCity']
        self.lo_mail_postal_code          = data['MailPostalCode']
        self.lo_mail_postal_code_plus4    = data['MailPostalCodePlus4']
        self.lo_mail_state_or_province    = data['MailStatOrProvince']
        self.matrix_unique_id             = data['Matrix_Unique_ID']
        self.lo_matrix_modified_dt        = data['MatrixModifiedDT']
        self.lo_mls                       = data['MLS']
        self.lo_mls_id                    = data['MLSID']
        self.lo_office_contact_mui        = data['OfficeContact_MUI']
        self.lo_office_contact_mls_id     = data['OfficeContactMLSID']        
        self.lo_office_long_name          = data['OfficeLongName']
        self.lo_office_name               = data['OfficeName']
        self.lo_phone                     = data['Phone']
        self.lo_photo_count               = data['PhotoCount']
        self.photo_modification_timestamp = data['PhotoModificationTimestamp']        
        self.state                        = data['State']
        self.street_address               = data['StreetAddress']
        self.street_city                  = data['StreetCity']
        self.street_postal_code           = data['StreetPostalCode']
        self.street_postal_code_plus4     = data['StreetPostalCodePlus4']
        self.street_state_or_province     = data['StreeStateOrProvince']
        self.web_facebook                 = data['WebFacebook']
        self.web_linked_in                = data['WebLinkedIn']
        self.web_page_address             = data['WebPageAddress']
        self.web_twitter                  = data['WebTwitter']
        self.zip                          = data['ZIP'] 
  end
end
