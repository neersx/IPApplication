ko.bindingHandlers.dataAttributes = {
    init: function (element, valueAccessor) {
        var attributes = ko.toJS(valueAccessor()) || [];
        $.each(attributes, function (index, attribute) {
            element.setAttribute(attribute.key, attribute.value);
        });
    }
};