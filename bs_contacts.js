$.each($(".btn.primary"), function() { $(this).click(); });

phones = $(".hover_edit .icon-bs-phone");
$.each(phones, function() {
  var $btn = $($(this)).parent().siblings().last().find("a").last();
  if ($btn.text() !== "Add all") {
    $($(this)).parent().siblings().last().find("a").last().click();
  }
});

emails = $(".hover_edit .icon-bs-email");
$.each(emails, function() {
  var $btn = $($(this)).parent().siblings().last().find("a").last();
  if ($btn.text() !== "Add all") {
    $($(this)).parent().siblings().last().find("a").last().click();
  }
});
