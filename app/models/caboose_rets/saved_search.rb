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
      when 'property'     then return CabooseRets::Property      
    end  
    return nil
  end

  def search_fields()
    return {
      'area'                     => '',
        'area_like'                => '',      
        'acreage_gte'              => '',
        'acreage_lte'              => '',
        'city'                     => '',
        'city_like'                => '',
        'county_or_parish'         => '',
        'county_or_parishy_like'   => '',
        'current_price_gte'        => '',
        'current_price_lte'        => '',
        'bedrooms_gte'             => '',
        'bedrooms_lte'             => '',
        'property_type'            => '',
        'property_subtype'         => '',
        'sqft_total_gte'           => '',
        'sqft_total_gte_lte'       => '',
        'neighborhood'             => '',
        'elementary_school'        => '',
        'middle_school'            => '',
        'high_school'              => '',          
        'public_remarks_like'      => '',
        'waterfronts'              => '',
        'waterfronts_not_null'     => '',
        'mls_number'               => '',
        'subdivision'              => '',
        'style'                    => '',
        'foreclosure_yn'           => '',
        'address_like'             => '',
        'street_name_like'         => '',
        'street_num_like'          => '',
        'postal_code'              => '',
        'postal_code_like'         => '',        
        'status'                   => 'Active'
      }
  end
  
  def search_options
    return {
      'model'           => self.model.to_s,
      'sort'            => 'current_price ASC, mls',
      'desc'            => false,
      'base_url'        => "/#{self.property_type}",
      'items_per_page'  => 10
    }
  end
  
end
