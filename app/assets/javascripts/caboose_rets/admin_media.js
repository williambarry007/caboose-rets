
var MediaController = function(options) { this.init(options) };

MediaController.prototype = {
  
  cdn_domain: false,
  s3_domain: false,
  mls_acct: false,
  
  s3_url: function(url)
  {
    if (!this.cnd_domain || !this.s3_domain)
      return url;
    return url.replace(this.cdn_domain, s3_domain);
  },
  
  init: function(options)
  {
    for (var thing in options)
      this[thing] = options[thing];
    
    var that = this;
    this.image_add_form();
    this.file_add_form();
    this.render_images(function() { that.sortable_images(); });
    this.render_files(function() { that.sortable_files(); });
  },
  
  sortable_images: function()
  { 
    var that = this;
    $('#images').sortable({      
      placeholder: 'sortable-placeholder',
      handle: '.sort_handle',      
      update: function(e, ui) {                                
        $.ajax({
          url: '/admin/properties/' + that.mls_acct + '/media/order',
          type: 'put',
          data: $('#images').sortable('serialize', { key: 'sort[]' }),
          success: function(resp) {}
        });        
      }
    });
  },
  
  sortable_files: function()
  {  
    $('#files').sortable({      
      placeholder: 'sortable-placeholder',
      handle: '.sort_handle',      
      update: function(e, ui) {                                
        $.ajax({
          url: '/admin/properties/' + that.mls_acct + '/media/order',
          type: 'put',
          data: $('#files').sortable('serialize', { key: 'sort[]' }),
          success: function(resp) {}
        });        
      }
    });
  },
          
  delete_image: function(media_id, confirm)
  {    
    var that = this;        
    if (!confirm)
    {
      var p = $('<p/>')
        .addClass('note warning')
        .append("Are you sure you want to delete the image? ")
        .append($('<input/>').attr('type', 'button').val('Yes').click(function() { that.delete_image(media_id, true); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('No').click(function()  { that.render_image(media_id); }));
      $('#image_' + media_id).attr('onclick','').unbind('click');
      $('#image_' + media_id).empty().append(p);
      return;
    }
    $('#image_' + media_id).empty().append($('<p/>').addClass('loading').html('Deleting image...'));
    $.ajax({
      url: '/admin/media/' + media_id,
      type: 'delete',
      success: function(resp) {
        that.render_images();      
      }
    });    
  },
  
  delete_file: function(media_id, confirm)
  {
    var that = this;        
    if (!confirm)
    {
      var p = $('<p/>')
        .addClass('note warning')
        .append("Are you sure you want to delete the file? ")
        .append($('<input/>').attr('type', 'button').val('Yes').click(function() { that.delete_file(media_id, true); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('No').click(function()  { that.render_file(media_id); }));
      $('#file_' + media_id).attr('onclick','').unbind('click');
      $('#file_' + media_id).empty().append(p);
      return;
    }
    $.ajax({
      url: '/admin/media/' + media_id,
      type: 'delete',
      success: function(resp) {
        that.render_files();      
      }
    });    
  },
    
  /*****************************************************************************
  Block Rendering
  *****************************************************************************/

  render_images: function(after)
  {
    $('#images').empty().append($('<p/>').addClass('loading').html('Getting images...'));    
    var that = this;
    $.ajax({      
      url: '/admin/properties/' + this.mls_acct + '/photos',
      success: function(media) {
        $('#images').empty();
        $(media).each(function(i,m) {            
          $('#images')
            .append($('<li/>')
              .attr('id', 'image_container_' + m.id)                                          
              .append($('<a/>').attr('id', 'image_' + m.id + '_sort_handle'  ).addClass('sort_handle'  ).append($('<span/>').addClass('ui-icon ui-icon-arrow-4')))
              .append($('<a/>').attr('id', 'image_' + m.id + '_delete_handle').addClass('delete_handle').append($('<span/>').addClass('ui-icon ui-icon-close')).click(function(e) { e.preventDefault(); that.delete_image(m.id); }))
              .append($('<div/>').attr('id', 'image_' + m.id).append($('<img/>').attr('src', that.s3_url(m.image.tiny_url) + '?' + Math.random()).attr('title', m.id + ' ' + m.image.file_name)))
            );
        });
        if (after) after();
      }
    });    
  },
  
  render_image: function(media_id, after)
  {    
    var that = this;
    $.ajax({
      url: '/admin/media/' + media_id,
      success: function(m) {        
        $('#image_' + m.id).empty().append($('<img/>').attr('src', that.s3_url(m.image.tiny_url) + '?' + Math.random()).attr('title', m.id));    
        if (after) after();
      }
    });
  },
  
  render_files: function(after)
  {
    $('#files').empty().append($('<p/>').addClass('loading').html('Getting files...'));        
    var that = this;
    $.ajax({      
      url: '/admin/properties/' + this.mls_acct + '/files',
      success: function(media) {
        $('#files').empty();
        if (!media || media.length == 0)
          $('#files').append($('<p/>').html('There are no files right now.'));
        $(media).each(function(i,m) {
          $('#files')
            .append($('<li/>')
              .attr('id', 'file_container_' + m.id)                                          
              .append($('<a/>').attr('id', 'file_' + m.id + '_sort_handle'  ).addClass('sort_handle'  ).append($('<span/>').addClass('ui-icon ui-icon-arrow-2-n-s')))
              .append($('<a/>').attr('id', 'file_' + m.id + '_delete_handle').addClass('delete_handle').append($('<span/>').addClass('ui-icon ui-icon-close')).click(function(e) { e.preventDefault(); that.delete_file(m.id); }))
              .append($('<div/>').attr('id', 'file_' + m.id).append($('<a/>').attr('href', m.file.url).html(m.file.file_name)))
            );
        });
        if (after) after();
      }
    });    
  },
  
  render_file: function(media_id, after)
  {    
    var that = this;
    $.ajax({
      url: '/admin/media/' + media_id,
      success: function(m) {
        $('#file_' + m.id).empty().append($('<a/>').attr('href', m.file.url).html(m.file.file_name));        
        if (after) after();
      }
    });
  },
  
  image_add_form: function()
  {    
    var that = this;
    var form = $('<form/>')
      .attr('id', 'new_image_form')
      .attr('action', '/admin/properties/' + this.mls_acct +'/photos')
      .attr('method', 'post')
      .attr('target', 'image_upload_iframe')
      .attr('enctype', 'multipart/form-data')
      .append($('<p/>')      
        .append($('<input/>').attr('type', 'hidden').attr('name', 'authenticity_token').val(this.auth_token))
        .append($('<input/>').attr('type', 'button').val('Upload New Image').click(function() { $('#image').click(); }))
        .append($('<input/>').attr('type', 'file').attr('id', 'image').attr('name', 'image')
          .css({ visibility: 'hidden', width: 0, height: 0 })          
          .change(function() {
            $('#new_image_form').submit();
            $('#new_image_form').hide();
            $('#new_image').append($('<p/>').addClass('loading').html("Adding image..."));
          })
        )
      );
    $('#new_image').empty()
      .append(form)      
      .append($('<iframe/>').attr('name', 'image_upload_iframe').css({ visibility: 'hidden', width: 0, height: 0 }));
  },
  
  after_image_upload: function()
  {   
    this.image_add_form();
    this.render_images();        
  },
  
  file_add_form: function()
  {    
    var that = this;
    var form = $('<form/>')
      .attr('id', 'new_file_form')
      .attr('action', '/admin/properties/' + this.mls_acct +'/files')
      .attr('method', 'post')
      .attr('target', 'file_upload_iframe')
      .attr('enctype', 'multipart/form-data')
      .append($('<p/>')      
        .append($('<input/>').attr('type', 'hidden').attr('name', 'authenticity_token').val(this.auth_token))
        .append($('<input/>').attr('type', 'button').val('Upload New File').click(function() { $('#file').click(); }))
        .append($('<input/>').attr('type', 'file').attr('id', 'file').attr('name', 'file')
          .css({ visibility: 'hidden', width: 0, height: 0 })          
          .change(function() {
            $('#new_file_form').submit();
            $('#new_file_form').hide();
            $('#new_file').append($('<p/>').addClass('loading').html("Adding file..."));
          })
        )
      );
    $('#new_file').empty()
      .append(form)
      .append($('<iframe/>').attr('name', 'file_upload_iframe').css({ visibility: 'hidden', width: 0, height: 0 }));
  },
  
  after_file_upload: function()
  {   
    this.file_add_form();
    this.render_files();        
  }

};
