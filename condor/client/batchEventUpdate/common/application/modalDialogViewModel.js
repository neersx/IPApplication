var application = (function(my) {
    my.modalDialogViewModel = function (onClosedCallback) {
        var renderedElement = null;
        var m = {
            onClosedCallback : onClosedCallback
        };

        m.onViewRendered = function (element) {
            renderedElement = $(element).filter('.modal').first();
            renderedElement.on('hidden.bs.modal', function () {
                if (!m.onClosedCallback)
                    return;
                m.onClosedCallback();
            });
            renderedElement.modal();
        };

        m.close = function () {
            if (!renderedElement)
                return;
            
            renderedElement.modal('hide');
        };
        
        return m;
    };
    return my;
}(application || { }))