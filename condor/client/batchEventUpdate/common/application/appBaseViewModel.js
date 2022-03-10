var application = (function(my) {
    my.appBaseViewModel = function() {
        var m = {
            messageBox: ko.observable(),
            currentView: ko.observable(),
            currentUser: ko.observable(),
            systemInfo: ko.observable()
        };

        ko.postbox.subscribe(application.messages.showDialog, function(options) {
            options.onClosedCallback = function() {
                m.messageBox(null);
            };

            m.messageBox(application.messageBoxViewModel(options));
        });

        ko.postbox.subscribe('applicationDetail', function(applicationDetail) {
            if (applicationDetail.currentUser)
                m.currentUser(applicationDetail.currentUser);
            if (applicationDetail.systemInfo)
                m.systemInfo(applicationDetail.systemInfo);
        });

        return m;
    };

    return my;
}(application || {}));
