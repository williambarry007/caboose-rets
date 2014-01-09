
var CabooseRets = function() {};
  
CabooseRets.search_params = {
  uri: window.location.pathname,
  property_type: "residential",
  params: false
};
      
CabooseRets.save_search = function(uri, property_type, params)
{  
  $.ajax({
    url: '/saved-searches',
    type: 'post',
    data: CabooseRets.search_params,
    success: function(resp) {
      caboose_modal_url(resp.redirect);
    }
  });
};

CabooseRets.get_save_property = function(mls_acct, el)
{
  $.ajax({
    url: '/saved-properties/' + mls_acct + '/status',
    type: 'get',
    success: function(resp) {
      if (resp.saved == true) el.html("<span style='color: #e5cd58; font-size: 2em;'>&#9733;</span> Saved");
      else                    el.html("<span style='color: #e5cd58; font-size: 2em;'>&#9734;</span> Save Listing");            
    }
  });
}

CabooseRets.toggle_save_property = function(mls_acct, el)
{
  $.ajax({
    url: '/saved-properties/' + mls_acct + '/toggle',
    type: 'get',
    success: function(resp) {
      if (resp.saved == true) el.html("<span style='color: #e5cd58; font-size: 2em;'>&#9733;</span> Saved");
      else                    el.html("<span style='color: #e5cd58; font-size: 2em;'>&#9734;</span> Save Listing");            
    }
  });
}

$(document).ready(function() {
  caboose_modal('login');            
  caboose_modal('saved_searches_button');
  
  $('#save_search').click(function(e) {
    e.preventDefault();
    CabooseRets.save_search();
  });

  $('.toggle_save_property').click(function(e) {
    e.preventDefault();
    var mls_acct = $(e.target).data('mls_acct');
    CabooseRets.toggle_save_property(mls_acct, $(e.target));    
  });
    
  $('.toggle_save_property').each(function(i, el) {
    var mls_acct = $(el).data('mls_acct');
    CabooseRets.get_save_property(mls_acct, $(el));
  });
    
});
