
class CabooseRets::OpenHouse < ActiveRecord::Base
  self.table_name = "rets_open_houses"
  
  has_one :property, :primary_key => 'listing_mui', :foreign_key => 'mls_number'  
  attr_accessible :id, :matrix_unique_id, :hide
  
  # def property
  #   models = [CabooseRets::Property]
  #   models.each do |model|
  #     id = self.mls_acct.to_i
  #     return model.find(id) if model.exists?(id)
  #   end
  #   return nil
  # end
  
  def agent
    return CabooseRets::Agent.where(:mls_id => self.mls_id).first if CabooseRets::Agent.exists?(:mls_id => self.mls_id)
    return nil
  end
  
  def parse(data)
    #    self.active_yn          = data['ActiveYN']
        self.description        = data['OpenHouseRemarks']
        self.end_time           = data['OpenHouseEndTime']
     #   self.entry_order        = data['EntryOrder']
        self.listing_mui        = data['ListingId']
        self.matrix_unique_id   = data['OpenHouseKey']
        self.matrix_modified_dt = data['ModificationTimestamp']
        self.open_house_date    = data['OpenHouseDate']
        self.open_house_type    = data['OpenHouseType']
        self.provider_key       = data['ShowingAgentKey']
        self.refreshments       = data['Refrehments']
        self.start_time         = data['OpenHouseStartTime'] 
  end
end
