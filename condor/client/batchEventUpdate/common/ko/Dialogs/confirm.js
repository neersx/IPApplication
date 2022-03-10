var dialogs = function (my) {
    my.confirm = function (options) {
        var attributes = [{ key: "data-dismiss", value: 'modal' }];

        var btnOk = localise.getString('btnOk');
        var btnCancel = localise.getString('btnCancel');

        options.buttons = [application.toolbarButtonViewModel(btnOk, {
            dataAttributes: attributes,
            clicked: options.accept
        }), application.toolbarButtonViewModel(btnCancel, {
            dataAttributes: attributes,
            clicked: options.reject
        })];

        ko.postbox.publish(application.messages.showDialog, options);
    };
    return my;
}(dialogs || {});
