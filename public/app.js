// app.js

$(document).ready(function() {
    $('#edit-item-modal').submit(function(event) {
      event.preventDefault();
  
      var form = $(this);
      var url = form.attr('action');
      var method = form.find('input[name="_method"]').val();
      var data = form.serialize();
  
      $.ajax({
        url: url,
        method: method,
        data: data,
        success: function(response) {
          // Update the item details on the page
          $('#item-name').text(response.name);
          $('#item-description').text(response.description);
  
          // Hide the modal
          $('#edit-item-modal').modal('hide');
        },
        error: function(xhr, status, error) {
          // Handle errors...
        }
      });
    });
  });
  