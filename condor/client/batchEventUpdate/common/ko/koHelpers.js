var utils = function(my) {
    my.koHelpers = {
        subscribeToAny : function(observables, handler) {
            $.each(observables, function (i, o) {
                o.subscribeChanged(handler);
            });
        }
    };

    return my;
}(utils || {});