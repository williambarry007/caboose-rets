require 'caboose'

module CabooseRets
  
  def CabooseRets.get_property(mls_acct)
    return nil if mls_acct.nil?
    models = [
      CabooseRets::ResidentialProperty, 
      CabooseRets::CommercialProperty, 
      CabooseRets::LandProperty, 
      CabooseRets::MultiFamilyProperty
    ]
    models.each do |model|
      return model.find(mls_acct.to_i) if model.exists?(mls_acct.to_i)            
    end
    return nil
  end
  
  class Engine < ::Rails::Engine
    isolate_namespace CabooseRets
  end
end
