var localise = (function(my) {
    'use strict';

    var _resources = {};
    var r = {};

    r.loaded = ko.observable(0);

    r.initialize = function(resources) {
        for (var key in resources) {
            _resources[key] = resources[key];
        }
        r.loaded(1);
    };

    r.getString = function(key) {

        if (!key) {
            throw 'key is required';
        }

        var result = _resources[key];

        for (var i = 1; i < arguments.length; i++) {
            result = result.replace('{' + (i - 1) + '}', arguments[i]);
        }

        return result;
    };

    r.load = function(resourceApi) {
        httpClient.json(resourceApi, function(data) {
            r.initialize(data.__resources || {});
            r.loaded(2);
        });
    };

    return r;

}(localise || {}));
