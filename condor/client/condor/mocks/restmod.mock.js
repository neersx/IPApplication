angular.module('inprotech.mocks').factory('restmodMock', function() {
    'use strict';

    var r = {
        model: function() {
            var r2 = createModel();
            r.model.returnValue = r2;
            return r2;
        }
    };

    spyOn(r, 'model').and.callThrough();

    return r;

    function createModel() {
        var model = {
            $search: function() {
                return {
                    $asPromise: function() {
                        return {
                            then: angular.noop
                        };
                    }
                };
            }
        };

        spyOn(model, '$search').and.callThrough();

        return model;
    }
});
