ko.bindingHandlers.collapse = {
    init: function (element, valueAccessor) {
        var options = ko.toJS(valueAccessor()) || {};
        if (!options.isDefault)
            return;
        $(element).addClass('in');
    }
};