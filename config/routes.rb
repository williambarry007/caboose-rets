CabooseRets::Engine.routes.draw do

  # get  "/property"                              => "property#index"
  # get  "/proprery/:id"                          => "property#details"
  # get  "/admin/property"                        => "property#admin_index"
  # get  "/admin/property/refresh"                => "property#admin_refresh"
  # get  "/property/search-options"               => "property#search_options"
  # get  "/property/search:search_params"         => "property#index", :constraints => {:search_params => /.*/}
  # get  "/property/:mls/details"                 => "property#details"
  # get  "/property/:mls"                         => "property#details"
  # get  "/admin/property/:mls/edit"              => "property#admin_edit"
  # get  "/admin/property/:mls/refresh"           => "property#admin_refresh"
  # put  "/admin/property/:mls"                   => "property#admin_update"
  # post "/admin/property/:mls"                   => "property#admin_update"



  # get  "/agents"                                   => "agents#index"
  # get  "/agents/:la_code"                          => "agents#details"
  # get  "/agents/:la_code/listings"                 => "agents#listings"
  # get  "/admin/agents"                             => "agents#admin_index"
  # get  "/admin/agents/assistant-to-options"        => "agents#admin_assistant_to_options"
  # get  "/admin/agents/options"                     => "agents#agent_options"
  # get  "/admin/agents/:id/edit"                    => "agents#admin_edit"
  # get  "/admin/agents/:id/edit-bio"                => "agents#admin_edit_bio"
  # get  "/admin/agents/:id/edit-contact-info"       => "agents#admin_edit_contact_info"
  # get  "/admin/agents/:id/edit-mls-info"           => "agents#admin_edit_mls_info"
  # get  "/admin/agents/:id/refresh"                 => "agents#admin_refresh"
  # put  "/admin/agents/:id"                         => "agents#admin_update"
  # post "/admin/agents/:id"                         => "agents#admin_update"

  get  "/open-houses"                              => "open_houses#index"
  get  "/open-houses/:id"                          => "open_houses#details"
  get  "/admin/open-houses"                        => "open_houses#admin_index"
  get  "/admin/open-houses/refresh"                => "open_houses#admin_refresh"

  get  "/admin/offices/options"                    => "offices#admin_options"
  get  "/admin/offices"                            => "offices#admin_index"
  get  "/admin/offices/:id"                        => "offices#admin_edit"
  get  "/admin/offices/:id/refresh"                => "offices#admin_refresh"

  get  "/admin/rets/import"                        => "rets#admin_import_form"
  post "/admin/rets/import"                        => "rets#admin_import"

  get  "/commercial/search:search_params"          => "commercial#index", :constraints => {:search_params => /.*/}
  get  "/commercial/:mls/details"             => "commercial#details"
  get  "/commercial/:mls"                     => "commercial#details"
  get  "/commercial"                               => "commercial#index"
  get  "/admin/commercial/new"                     => "commercial#admin_new"
  post "/admin/commercial"                         => "commercial#admin_add"
  get  "/admin/commercial"                         => "commercial#admin_index"
  get  "/admin/commercial/:mls/edit"          => "commercial#admin_edit"
  get  "/admin/commercial/:mls/refresh"       => "commercial#admin_refresh"
  put  "/admin/commercial/:mls"               => "commercial#admin_update"
  post "/admin/commercial/:mls"               => "commercial#admin_update"

  get  "/residential/search-options"               => "residential#search_options"
  get  "/residential/search:search_params"         => "residential#index", :constraints => {:search_params => /.*/}
  get  "/residential/:mls/details"            => "residential#details"
  get  "/residential/:mls"                    => "residential#details"
  get  "/residential"                              => "residential#index"
  get  "/admin/residential"                        => "residential#admin_index"
  get  "/admin/residential/:mls/edit"         => "residential#admin_edit"
  get  "/admin/residential/:mls/refresh"      => "residential#admin_refresh"
  put  "/admin/residential/:mls"              => "residential#admin_update"
  post "/admin/residential/:mls"              => "residential#admin_update"

  get  "/land/search:search_params"                => "land#index", :constraints => {:search_params => /.*/}
  get  "/land/:mls/details"                   => "land#details"
  get  "/land/:mls"                           => "land#details"
  get  "/land"                                     => "land#index"
  get  "/admin/land"                               => "land#admin_index"
  get  "/admin/land/:mls/edit"                => "land#admin_edit"
  get  "/admin/land/:mls/refresh"             => "land#admin_refresh"
  put  "/admin/land/:mls"                     => "land#admin_update"
  post "/admin/land/:mls"                     => "land#admin_update"

  get  "/multi-family/search:search_params"        => "multi_family#index", :constraints => {:search_params => /.*/}
  get  "/multi-family/:mls/details"           => "multi_family#details"
  get  "/multi-family/:mls"                   => "multi_family#details"
  get  "/multi-family"                             => "multi_family#index"
  get  "/admin/multi-family"                       => "multi_family#admin_index"
  get  "/admin/multi-family/:mls/edit"        => "multi_family#admin_edit"
  get  "/admin/multi-family/:mls/refresh"     => "multi_family#admin_refresh"
  put  "/admin/multi-family/:mls"             => "multi_family#admin_update"
  post "/admin/multi-family/:mls"             => "multi_family#admin_update"

  get    "/saved-searches"                         => "saved_searches#index"
  post   "/saved-searches"                         => "saved_searches#add"
  get    "/saved-searches/:id"                     => "saved_searches#redirect"
  put    "/saved-searches/:id"                     => "saved_searches#update"
  delete "/saved-searches/:id"                     => "saved_searches#delete"

  get    "/saved-properties/:mls/status"      => "saved_properties#status"
  get    "/saved-properties/:mls/toggle"      => "saved_properties#toggle_save"
  get    "/saved-properties"                       => "saved_properties#index"
  post   "/saved-properties"                       => "saved_properties#add"
  delete "/saved-properties/:mls"             => "saved_properties#delete"

  get    "/admin/properties/:mls/photos"       => "rets_media#admin_photos"
  get    "/admin/properties/:mls/files"        => "rets_media#admin_files"
  get    "/admin/properties/:mls/media"        => "rets_media#admin_property_media"
  put    "/admin/properties/:mls/media/order"  => "rets_media#admin_update_order"
  post   "/admin/properties/:mls/photos"       => "rets_media#admin_add_photo"
  post   "/admin/properties/:mls/files"        => "rets_media#admin_add_file"
  get    "/admin/rets/media/:id"                    => "rets_media#admin_index"
  delete "/admin/rets/media/:id"                    => "rets_media#admin_delete"

end
