angular.module('inprotech.mocks').factory('hotkeysMock', function() {
    'use strict';

    //note: inject hotkey mock in controller rather than in module initialisation
    // since the 'add' will be monkey patched.

    var service = {
        isMock: true,
        add: function() {},
        del: function() {},
        get: function() {},
        purgeHotkeys: function() {}
    };

    test.spyOnAll(service);

    return service;
});
