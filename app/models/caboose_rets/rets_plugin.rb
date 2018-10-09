class CabooseRets::RetsPlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user = nil, page = nil, site)  
    return nav if user.nil?
    return nav if !site.use_rets    
    return nav if !user.is_allowed('properties', 'view')
    
    item = {
      'id' => 'rets',
      'text' => 'Real Estate', 
      'children' => [],
      'modal' => true
    }    
    item['children'] << { 'id' => 'agents', 'icon' => 'users',    'href' => '/admin/agents'           , 'text' => 'Agents'                , 'modal' => false }
    # item['children'] << { 'id' => 'offices'          , 'href' => '/admin/offices'          , 'text' => 'Offices'               , 'modal' => false }
    # item['children'] << { 'id' => 'open-houses'      , 'href' => '/admin/open-houses'      , 'text' => 'Open Houses'           , 'modal' => false }
    item['children'] << { 'id' => 'properties'      , 'icon' => 'rets', 'href' => '/admin/properties'      , 'text' => 'Properties'  , 'modal' => false }
    # item['children'] << { 'id' => 'commercial'       , 'href' => '/admin/commercial'       , 'text' => 'Commercial Property'   , 'modal' => false }
    # item['children'] << { 'id' => 'commercial'       , 'href' => '/admin/multi-family'     , 'text' => 'Multi-Family Property' , 'modal' => false }
    # item['children'] << { 'id' => 'land'             , 'href' => '/admin/land'             , 'text' => 'Land Property'         , 'modal' => false }
    # item['children'] << { 'id' => 'saved-properties' , 'href' => '/saved-properties'       , 'text' => 'Saved Properties'      , 'modal' => false }
    # item['children'] << { 'id' => 'saved-searches'   , 'href' => '/saved-searches'         , 'text' => 'Saved Searches'        , 'modal' => false }    
    
    nav << item
    
    return nav
  end
  
end
