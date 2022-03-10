var application = (function (my) {
    my.windowViewModel = function (windowName, options) {
        options = options || { };
        return {
            windowName: windowName,
            toolbarButtons: options.toolbarButtons || []
        };
    };
    return my;
}(application || { }));