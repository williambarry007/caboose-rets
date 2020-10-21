class CabooseRets::SearchOption < ActiveRecord::Base
  self.table_name = "rets_search_options"

  # attr_accessible :id, :name, :field, :value, :flag_for_delete
                                 
  def self.update_search_options
    
    # Flag all for delete
    self.update_all(:flag_for_delete => true)
    
    names = {
      'City'          => ['city'],
      'County'        => ['county_or_parish'],
      'Zip Code'      => ['postal_code'],
      'Schools'       => ['elementary_school', 'middle_school', 'high_school'],
      'MLS Area'      => ['area'],
      'Neighborhood'  => ['subdivision'],
      'Street Name'   => ['street_name'],
      'Property Type' => ['property_type'],      
      'MLS Number'    => ['mls_number']
    }
    names.each do |name, fields|
      fields.each do |field|
        self.update_search_options_for_field(name, field)        
      end
    end
    
    # Delete all flagged
    self.where(:flag_for_delete => true).delete_all        
  end
  
  def self.update_search_options_for_field(name, field)
    q = ["select distinct(#{field}) from rets_properties where status = ?", 'Active']
    rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, q))
    rows.each do |row|
      so = self.where(:name => name, :field => field, :value => row[0]).first
      if so.nil? && !field.blank?
        self.create(:name => name, :field => field, :value => row[0])
      else      
        so.flag_for_delete = false
        so.save
      end
    end
  end
  
  def self.results(str, count_per_name = 10)      
    q = ["select * from (        
        select id, name, field, value, row_number() over (partition by name order by field) as rownum 
        from rets_search_options        
        where lower(value) like ?        
      ) tmp where rownum < #{count_per_name}", "%#{str}%"]      
    rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, q))
    arr = rows.collect{ |row| { :id => row[0].to_i, :name => row[1], :field => row[2], :text => row[3] }}    
    return arr    
  end
    
end
