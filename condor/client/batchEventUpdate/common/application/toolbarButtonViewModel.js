var application = (function (my) {
    var emptyClickedHandler = function () {

    };
    my.toolbarButtonViewModel = function (text, options) {
        options = options || {};
        return {
            name: ko.observable(options.name),
            text: ko.observable(text),
            visible: options.visible || ko.observable(true),
            enable: options.enable || ko.observable(true),
            icon: ko.isObservable(options.icon) ? options.icon : ko.observable(options.icon),
            clicked: options.clicked || emptyClickedHandler,
            isDefault: options.isDefault || false,
            dataAttributeCollection: ko.observableArray(options.dataAttributes)
        };
    };
    return my;
} (application || {}));