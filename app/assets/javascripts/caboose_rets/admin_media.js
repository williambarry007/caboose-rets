
var MediaController = function(mls_acct) { this.init(mls_acct); };

MediaController.prototype = {

  mls_acct: false,
  
  s3_url: function(url)
  {
    return url.replace("d19w6hbyh7z79c.cloudfront.net/", "s3.amazonaws.com/advantagerealtygroup/");
  },
  
  init: function(mls_acct)
  {
    this.mls_acct = mls_acct;
    var that = this;
    this.image_add_form();
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
          url: '/admin/media/' + that.mls_acct + '/order',
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
          url: '/admin/media/' + that.mls_acct + '/order',
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
      $('#image_' + media_id).attr('onclick','').unbind('click');
      $('#image_' + media_id).empty().append(p);
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
    $('#images').empty();    
    var that = this;
    $.ajax({      
      url: '/admin/media/' + this.mls_acct + '/photos',
      success: function(media) {
        $(media).each(function(i,m) {
          $('#images')
            .append($('<li/>')
              .attr('id', 'image_container_' + m.id)                                          
              .append($('<a/>').attr('id', 'image_' + m.id + '_sort_handle'  ).addClass('sort_handle'  ).append($('<span/>').addClass('ui-icon ui-icon-arrow-2-n-s')))
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
    $('#files').empty();    
    var that = this;
    $.ajax({      
      url: '/admin/media/' + this.mls_acct + '/files',
      success: function(media) {
        $(media).each(function(i,m) {
          $('#files')
            .append($('<li/>')
              .attr('id', 'file_container_' + m.id)                                          
              .append($('<a/>').attr('id', 'file_' + m.id + '_sort_handle'  ).addClass('sort_handle'  ).append($('<span/>').addClass('ui-icon ui-icon-arrow-2-n-s')))
              .append($('<a/>').attr('id', 'file_' + m.id + '_delete_handle').addClass('delete_handle').append($('<span/>').addClass('ui-icon ui-icon-close')).click(function(e) { e.preventDefault(); that.delete_file(m.id); }))
              .append($('<a/>').attr('id', 'file_' + m.id).attr('href', m.file.url).html(m.file.file_name))
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
        $('#file_' + m.id).attr('href', m.file.url).html(m.file.file_name);
        if (after) after();
      }
    });
  },
  
  image_add_form: function()
  {    
    var that = this;
    var form = $('<form/>')
      .attr('id', 'new_image_form')
      .attr('action', '/admin/media/' + this.mls_acct +'/photos')
      .attr('method', 'post')
      .attr('target', 'image_upload_iframe')
      .attr('enctype', 'multipart/form-data')      
      .append($('<input/>').attr('type', 'hidden').attr('name', 'authenticity_token').val(this.auth_token))
      .append($('<input/>').attr('type', 'file').attr('name', 'image').change(function() {
        $('#new_image_form').submit();
        $('#new_image_form').hide();
        $('#new_image').append($('<p/>').addClass('loading').html("Adding image..."));
      }));
    $('#new_image').empty()
      .append(form)
      .append($('<iframe/>').attr('name', 'image_upload_iframe').css('display', 'none'));
  },
  
  after_image_upload: function()
  {   
    this.image_add_form();
    this.render_images();        
  },   

};
