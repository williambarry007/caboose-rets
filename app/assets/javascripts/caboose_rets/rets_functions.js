function rets_save_property(mls_number) {
	$.ajax({
    url: '/api/save-property',
    type: 'put',
    data: {
    	mls: mls_number
    },
    success: function(resp) {
    	if (resp && resp.success) {
    		$.each( $("a[data-mls='" + mls_number + "']"), function(k,v) {
    			var oldoc = $(v).attr("onclick");
    			var newoc = $(v).attr("onclick2");
    			$(v).attr("onclick",newoc).attr("onclick2",oldoc);
    			$(v).mouseleave(function() {
    				$(v).addClass("active");
    			});
    		});
      }
    }
  });
}

function rets_unsave_property(mls_number) {
	$.ajax({
    url: '/api/unsave-property',
    type: 'put',
    data: {
    	mls: mls_number
    },
    success: function(resp) {
    	if (resp && resp.success) {
      	$.each( $("a[data-mls='" + mls_number + "']"), function(k,v) {
    			var oldoc = $(v).attr("onclick");
    			var newoc = $(v).attr("onclick2");
    			$(v).attr("onclick",newoc).attr("onclick2",oldoc);
    			$(v).mouseleave(function() {
    				$(v).removeClass("active");
    			});
    			if ( $(v).closest(".saved-list").length > 0 )
  					$(v).closest(".property").remove();
    		});
      }
    }
  });
}