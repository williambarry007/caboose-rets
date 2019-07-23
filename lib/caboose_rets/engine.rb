require 'caboose'

module CabooseRets
  
  def CabooseRets.get_property(mls)
    return nil if mls.nil?
    models = [
      CabooseRets::ResidentialProperty, 
      CabooseRets::CommercialProperty, 
      CabooseRets::LandProperty, 
      CabooseRets::MultiFamilyProperty
    ]
    models.each do |model|
      return model.find(mls.to_i) if model.exists?(mls.to_i)            
    end
    return nil
  end
  
  class Engine < ::Rails::Engine
    isolate_namespace CabooseRets
    initializer 'caboose_rets.assets.precompile' do |app|            
      app.config.assets.precompile += [
        'caboose_rets/admin_media.js',
        'caboose_rets/caboose_rets.js',
        'caboose_rets/rets_functions.js',
        'caboose_rets/retsicons.css',
        'caboose_rets/rets.eot',
        'caboose_rets/rets.svg',
        'caboose_rets/rets.ttf',
        'caboose_rets/rets.woff'
      ]      
    end
  end
end
