ko.bindingHandlers.slide = {
    init: function (element) {
        var e = $(element).find('.slide-down-head');
        e.click(function () {
            var body = $(element).find('.slide-down-body');
            var collapse = body.data('collapse');
            if (!collapse) {
                body.slideDown();
                body.data('collapse', true);
            }
            else {
                body.slideUp();
                body.removeData('collapse');
            }
        });
    }
};