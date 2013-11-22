class CabooseRets::RetsPlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user = nil, page = nil)
    return nav if user.nil?
    
    nav << {
      'id' => 'saved-searches',
      'text' => 'Saved Searches', 
      'href' => '/saved-searches',
      'modal' => true
    }
    
    return nav if !user.is_allowed('properties', 'view')
    
    item = {
      'id' => 'rets',
      'text' => 'RETS', 
      'children' => [],
      'modal' => true
    }
    
    item['children'] << { 'id' => 'agents'      , 'href' => '/admin/agents'           , 'text' => 'Agents'                , 'modal' => false }
    item['children'] << { 'id' => 'offices'     , 'href' => '/admin/offices'          , 'text' => 'Offices'               , 'modal' => false }
    item['children'] << { 'id' => 'open-houses' , 'href' => '/admin/open-houses'      , 'text' => 'Open Houses'           , 'modal' => false }
    item['children'] << { 'id' => 'residential' , 'href' => '/admin/residential'      , 'text' => 'Residential Property'  , 'modal' => false }
    item['children'] << { 'id' => 'commercial'  , 'href' => '/admin/commercial'       , 'text' => 'Commercial Property'   , 'modal' => false }
    item['children'] << { 'id' => 'commercial'  , 'href' => '/admin/multi-family'     , 'text' => 'Multi-Family Property' , 'modal' => false }
    item['children'] << { 'id' => 'land'        , 'href' => '/admin/land'             , 'text' => 'Land Property'         , 'modal' => false }    
    
    nav << item
    
    return nav
  end
  
end
