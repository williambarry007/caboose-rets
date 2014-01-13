require "caboose_rets/engine"

module CabooseRets

  mattr_accessor :default_property_sort
  @@default_property_sort = 'current_price DESC, mls_acct'

end
