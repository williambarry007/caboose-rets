class CabooseRets::Agent < ActiveRecord::Base
  self.table_name = "rets_agents"  
  
  has_one :meta, :class_name => 'AgentMeta', :primary_key => 'mls_id', :foreign_key => 'la_code'
  has_many :properties
  attr_accessible :id, :agent_number, :matrix_unique_id, :sort_order, :mls_id
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
    CabooseRets::RetsImporter.import('Member',"(MemberMlsId=#{self.mls_id})")
    CabooseRets::RetsImporter.download_property_images(self)
  end
  
  def self.refresh_from_mls(agent_number)
    CabooseRets::RetsImporter.import('Member', "(MemberMlsId=#{self.mls_id})")
    CabooseRets::RetsImporter.import_agent(self.mls_id)          
  end
    
  def parse(data)
#    self.agent_number                 = data['AgentNumber']
    self.cell_phone                   = data['MemberMobilePhone']
    self.direct_work_phone            = data['MemberDirectPhone']
    self.email                        = data['MemberEmail']
    self.fax_phone                    = data['MemberFax']
    self.first_name                   = data['MemberFirstName']
    self.full_name                    = data['MemberFullName']
   # self.generational_name            = data['MemberMiddleName']
    self.last_name                    = data['MemberLastName']
    self.matrix_unique_id             = data['MemberMlsId']
    self.matrix_modified_dt           = data['ModificationTimestamp']
    self.middle_name                  = data['MemberMiddleName']
    self.mls                          = 'West Alabama Multiple Listing Service'
    self.mls_id                       = data['MemberMlsId']
    self.office_mui                   = data['OfficeMlsId']
    self.office_mls_id                = data['OfficeMlsId']
    self.office_phone                 = data['MemberOfficePhone']
    self.other_phone                  = data['MemberPreferredPhone']
    self.phone_toll_free              = data['MemberTollFreePhone']
    self.phone_voice_mail             = data['MemberVoiceMail']        
  #  self.photo_count                  = data['PhotoCount']
  #  self.photo_modification_timestamp = data['PhotoModificationTimestamp']
    self.slug                         = "#{data['MemberFirstName']}-#{data['MemberLastName']}".parameterize
  end
  
  def verify_meta_exists
     self.meta = CabooseRets::AgentMeta.create(:la_code => self.mls_id) if self.meta.nil?
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
