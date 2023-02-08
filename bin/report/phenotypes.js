activeItem = undefined;

function setActive(e) {

  if (activeItem){
    activeItem.removeClass("active");
  }
  $(this).addClass("active");
  activeItem = $(this);
}



function filterPhenotypes(e) {
  var input = $(this).val()
  var filter = input.toUpperCase()
  $('.list-group .list-group-item').each(function() {
    var anchor = $(this)
    if (anchor.data('meta') == undefined || anchor.data('meta').toUpperCase().indexOf(filter) > -1) {
      anchor.removeClass('d-none')
    } else {
      anchor.addClass('d-none');
    }
  });
}


$(document).ready(function() {

  //event handler
  $('.list-group-item').on('click', setActive);
  $('#s').on('input', filterPhenotypes);

  console.log("Ready to explore data :)");

});
