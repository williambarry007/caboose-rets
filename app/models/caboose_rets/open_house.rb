
class CabooseRets::OpenHouse < ActiveRecord::Base
  self.table_name = "rets_open_houses"
  
  attr_accessible :id, :matrix_unique_id
  
  def property
    models = [CabooseRets::Property]
    models.each do |model|
      id = self.mls_acct.to_i
      return model.find(id) if model.exists?(id)
    end
    return nil
  end
  
  def agent
    return CabooseRets::Agent.where(:mls_id => self.mls_id).first if CabooseRets::Agent.exists?(:mls_id => self.mls_id)
    return nil
  end
  
  def parse(data)
        self.active_yn          = data['ActiveYN']
        self.description        = data['Description']
        self.end_time           = data['EndTime']
        self.entry_order        = data['EntryOrder']
        self.listing_mui        = data['ListingMUI']
        self.matrix_unique_id   = data['matrix_unique_id']
        self.matrix_modified_dt = data['MatrixModifiedDT']
        self.open_house_date    = data['OpenHouseDate']
        self.open_house_type    = data['OpenHouseType']
        self.provider_key       = data['ProviderKey']
        self.refreshments       = data['Refrehments']
        self.start_time         = data['StartTime'] 
  end
end
