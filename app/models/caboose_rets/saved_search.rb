class CabooseRets::SavedSearch < ActiveRecord::Base  
  self.table_name = 'rets_saved_searches'

  belongs_to :user
  attr_accessible :id, :user_id, :property_type, :uri, :params, :date_last, :interval, :notify
  
  # We're storing the params as JSON, so parse it when we init
  after_initialize do
    unless self.params.is_a?(Hash) || self.params.nil?
      obj = JSON.parse(self.params)
      self.params = obj
    end
  end 
  
  # Store it back as JSON
  before_save do
    obj = Caboose::StdClass.new(self.params)
    self.params = obj.to_json
  end

  def results()
    @gen = Caboose::PageBarGenerator.new(self.params, self.search_fields, self.search_options)
    return @gen.items
  end
  
  def new_results?()
    return false if self.new_results.nil? || self.new_results == []
  end
  
  def new_results
    return self.results.reject{|r|r.date_created.to_date > self.date_last.to_date }
  end

  def model
    case self.property_type
      when 'residential'  then return CabooseRets::ResidentialProperty
      when 'commercial'   then return CabooseRets::CommercialProperty
      when 'land'         then return CabooseRets::LandProperty
      when 'multi-family' then return CabooseRets::MultiFamilyProperty
    end  
    return nil
  end

  def search_fields()
    return {
      'name'               => '',
      'current_price_gte'  => '',
      'current_price_lte'  => '',
      'bedrooms_gte'       => '',
      'bedrooms_lte'       => '',
      'prop_type'          => '',
      'tot_heat_sqft_gte'  => '',
      'tot_heat_sqft_lte'  => '',
      'neighborhood'       => '',
      'elem_school'        => '',
      'middle_school'      => '',
      'high_school'        => '',
      'address'            => '',
      'lo_lo_code'         => '',
      'remarks_like'       => '',
      'waterfront'         => '',
      'ftr_lotdesc_like'   => '',
      'mls_acct'           => '',
      'subdivision'        => '',
      'foreclosure_yn'     => '',
      'street_name_like'   => '',
      'street_num_like'    => '',
      'date_created_gte'   => '',
      'date_created_lte'   => '',
      'date_modified_gte'  => '',
      'date_modified_lte'  => '',
      'status'             => ['active']
    }
  end
  
  def search_options
    return {
      'model'           => self.model.to_s,
      'sort'            => 'current_price ASC, mls_acct',
      'desc'            => false,
      'base_url'        => "/#{self.property_type}",
      'items_per_page'  => 10
    }
  end
  
end
