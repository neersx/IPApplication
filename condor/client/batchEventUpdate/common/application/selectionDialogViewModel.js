var application = (function (my) {
    my.selectionDialogViewModel = function (onClosedCallback) {        
        var m = application.modalDialogViewModel();
        m.selectedItem = ko.observable();        
        m.onClosedCallback = function() {
            if (!onClosedCallback)
                return;
            onClosedCallback(m.selectedItem());
        };
        return m;
    };
    return my;
}(application || { }));