class CabooseRets::RetsPlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user = nil, page = nil, site)  
    return nav if user.nil?
    return nav if !site.use_rets    
    return nav if !user.is_allowed('rets_properties', 'view')
    
    item = {
      'id' => 'rets',
      'text' => 'Real Estate', 
      'children' => [],
      'modal' => true
    }    
    item['children'] << { 'id' => 'agents', 'icon' => 'users',    'href' => '/admin/agents'           , 'text' => 'Agents'                , 'modal' => false }  if user.is_allowed('rets_agents','view')
    # item['children'] << { 'id' => 'offices'          , 'href' => '/admin/offices'          , 'text' => 'Offices'               , 'modal' => false }
    item['children'] << { 'id' => 'open-houses', 'icon' => 'calendars', 'href' => '/admin/open-houses'      , 'text' => 'Open Houses'           , 'modal' => false } if user.is_allowed('rets_open_houses','view')
    item['children'] << { 'id' => 'properties'      , 'icon' => 'rets', 'href' => '/admin/properties'     , 'text' => 'Properties'  , 'modal' => false }  if user.is_allowed('rets_properties','view')
    # item['children'] << { 'id' => 'commercial'       , 'href' => '/admin/commercial'       , 'text' => 'Commercial Property'   , 'modal' => false }
    # item['children'] << { 'id' => 'commercial'       , 'href' => '/admin/multi-family'     , 'text' => 'Multi-Family Property' , 'modal' => false }
    # item['children'] << { 'id' => 'land'             , 'href' => '/admin/land'             , 'text' => 'Land Property'         , 'modal' => false }
    # item['children'] << { 'id' => 'saved-properties' , 'href' => '/saved-properties'       , 'text' => 'Saved Properties'      , 'modal' => false }
    # item['children'] << { 'id' => 'saved-searches'   , 'href' => '/saved-searches'         , 'text' => 'Saved Searches'        , 'modal' => false }
    nav << item
    
    return nav
  end

  def self.admin_user_tabs(tabs, user, site)
    if site && site.use_rets
      arr = tabs.to_a.insert(-2, ['MLS Profile', "/admin/users/#{user.id}/mls"])
      tabs = Hash[arr]
      return tabs
    else
      return tabs
    end
  end
  
end