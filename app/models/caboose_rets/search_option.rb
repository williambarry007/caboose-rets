class CabooseRets::SearchOption < ActiveRecord::Base
  self.table_name = "rets_search_options"

  attr_accessible :id, :name, :field, :value
                                 
  def self.update_search_options
    
    names = {
      'City'          => ['city'],
      'County'        => ['county'],
      'Zip Code'      => ['zip'],
      'Schools'       => ['elem_school', 'middle_school', 'high_school'],
      'MLS Area'      => ['area'],
      'Neighborhood'  => ['subdivision'],
      'Street Name'   => ['street_name'],
      'Property Type' => ['prop_type'],      
      'MLS Number'    => ['mls_acct']      
      #'feature',            
      #'location',
    }
    names.each do |name, fields|
      fields.each do |field|          
        q = ["select distinct(#{field}) from rets_residential"]
        rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, q))
        rows.each do |row|
          so = self.where(:name => name, :field => field, :value => row[0]).first
          self.create(    :name => name, :field => field, :value => row[0]) if so.nil?
        end
      end
    end
  end
  
  def self.results(str, count_per_name = 10)      
    q = ["select * from (        
        select name, field, value, row_number() over (partition by name order by field) as rownum 
        from rets_search_options
        where lower(value) like ?
      ) tmp where rownum < #{count_per_name}", "%#{str}%"]      
    rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, q))
    arr = rows.collect{ |row| { :name => row[0], :field => row[1], :value => row[2] }}    
    return arr    
  end
    
end
