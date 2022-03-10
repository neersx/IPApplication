var batchEventUpdate = (function(my) {
    'use strict';
    my.logout = function() {
        if (!localStorage) {
            return;
        }

        localStorage.setItem('signin', "{}");
        return true;
    };

    return my;
}(batchEventUpdate || {}));