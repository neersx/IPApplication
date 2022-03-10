ko.bindingHandlers.popover = {
    update: function (element, valueAccessor) {
        var options = ko.toJS(valueAccessor()) || {};
        var target = $(element).siblings(options.targetSelector);

        if (options.titleTranslateId) {
            options.title = localise.getString(options.titleTranslateId);
        }

        target.popover({
            title: options.title,
            placement: options.placement,
            content: $(element).html(),
            html: true,
            trigger: 'hover'
        });
    }
};
