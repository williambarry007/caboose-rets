class CabooseRets::Agent < ActiveRecord::Base
  self.table_name = "rets_agents"  
  
  has_one :meta, :class_name => 'AgentMeta', :primary_key => 'matrix_unique_id', :foreign_key => 'matrix_unique_id'
  has_many :properties
  attr_accessible :id, :agent_number, :matrix_unique_id
  after_initialize :fix_name
  
  def image
    return nil if self.meta.nil?
    return self.meta.image
  end

  # def assistants
  #   CabooseRets::Agent.where(:assistant_to => self.mls_id).reorder(:last_name, :first_name).all
  # end

  def office
    CabooseRets::Office.where(:lo_mls_id => self.mls_id).first
  end
  
  def fix_name
    return if self.first_name.nil?
    self.first_name = self.first_name.split(' ').collect{ |str| str.downcase.capitalize }.join(' ')
    return if self.last_name.nil?          
    self.last_name  = self.last_name.split(' ').collect{ |str| str.downcase.capitalize }.join(' ')    
    if self.last_name.starts_with?('Mc')
      self.last_name[2] = self.last_name[2].upcase
    end
  end
  
  def refresh_from_mls        
    CabooseRets::RetsImporter.import('Listing',"(Matrix_Unique_ID=#{self.matrix_unique_id})")
    CabooseRets::RetsImporter.download_property_images(self)
  end
  
  def self.refresh_from_mls(agent_number)
    CabooseRets::RetsImporter.import('Agent', "(Agent_Number=#{self.agent_number})")
    CabooseRets::RetsImporter.import_property(matrix_unique_id)          
  end
    
  def parse(data)
    self.agent_number                 = data['AgentNumber']
    self.cell_phone                   = data['CellPhone']
    self.direct_work_phone            = data['DirectWorkPhone']
    self.email                        = data['Email']
    self.fax_phone                    = data['FaxPhone']
    self.first_name                   = data['FirstName']
    self.full_name                    = data['FullName']
    self.generational_name            = data['GenerationalName']
    self.last_name                    = data['LastName']
    self.matrix_unique_id             = data['Matrix_Unique_ID']
    self.matrix_modified_dt           = data['MatrixModifiedDT']
    self.middle_name                  = data['MiddleName']
    self.mls                          = data['MLS']
    self.mls_id                       = data['MLSID']
    self.office_mui                   = data['Office_MUI']
    self.office_mls_id                = data['OfficeMLSID']
    self.office_phone                 = data['OfficePhone']
    self.other_phone                  = data['OtherPhone']
    self.phone_toll_free              = data['PhoneTollFree']
    self.phone_voice_mail             = data['PhoneVoiceMail']        
    self.photo_count                  = data['PhotoCount']
    self.photo_modification_timestamp = data['PhotoModificationTimestamp'] 
  end
  
  def verify_meta_exists
     self.meta = CabooseRets::AgentMeta.create(:la_code => self.la_code) if self.meta.nil?
  end
  
  def image_url(style)                
    if CabooseRets::use_hosted_images == true
      return "#{CabooseRets::agents_base_url}/#{self.image_location}"
      self.verify_meta_exists      
      return self.meta.image_location
    end
    return "" if self.image.nil?
    return self.image.url(style)           
  end
     
end
