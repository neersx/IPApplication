var application = (function(my) {
    my.messageBoxViewModel = function(options) {
        options = options || { };

        var m = application.modalDialogViewModel(options.onClosedCallback);

        return $.extend(m, {
            title: ko.isObservable(options.title) ? options.title : ko.observable(options.title),
            message: ko.isObservable(options.message) ? options.message : ko.observable(options.message),
            type: ko.isObservable(options.type) ? options.type : ko.observable(options.type),
            buttons: ko.isObservable(options.buttons) ? options.buttons : ko.observable(options.buttons)
        });
    };

    return my;
}(application || { }));