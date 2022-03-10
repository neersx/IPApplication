ko.bindingHandlers.select = {
    init: function (element, valueAccessor) {
        $(element).focusin(function() {
            valueAccessor()(true);
        });

        $(element).focusout(function() {
            valueAccessor()(false);
        });
    }
};
