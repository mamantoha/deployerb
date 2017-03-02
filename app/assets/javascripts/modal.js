$(function() {
  $('body').on('hidden.bs.modal', '.modal', function () {
    $(this).removeData('bs.modal');
  });
});

// Focus on input inside a modal on click
$(function() {
  $('body').on('shown.bs.modal', '.modal', function () {
    $("#name").focus();
  });
});

$('document').ready(function () {
  if ($('#error-explanation').length > 0) {
    $("#addResource").css("display", "block");
  }
});

$('document').ready(function () {
  if ($('#error-explanation').length > 0) {
    $("#addResource").modal('toggle');
  };
});
