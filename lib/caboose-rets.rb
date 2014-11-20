require "caboose_rets/engine"

module CabooseRets

  mattr_accessor :default_property_sort
  @@default_property_sort = 'current_price DESC, mls_acct'
  
  mattr_accessor :use_hosted_images
  @@use_hosted_images = true
  
  mattr_accessor :media_base_url
  @@media_base_url = ''
  
  mattr_accessor :agents_base_url
  @@agents_base_url = ''
  
  mattr_accessor :offices_base_url
  @@offices_base_url = ''
  
end
