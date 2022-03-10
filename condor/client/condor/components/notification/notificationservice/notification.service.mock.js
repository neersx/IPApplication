angular.module('inprotech.mocks.components.notification').factory('notificationServiceMock', function() {
    'use strict';

    var promiseMock = test.mock('promise');

    var r = {
        discard: jasmine.createSpy('discard-spy', function() {
            return {
                then: function(cb) {
                    if (r.discard.confirmed) {
                        cb();
                    }

                    return this;
                }
            };
        }).and.callThrough(),
        unsavedchanges: jasmine.createSpy('unsaved-changes-spy',
            function() {
                return {
                    then: function(cb) {
                        if (r.unsavedchanges.discard) {
                            cb();
                        } else if (r.unsavedchanges.save) {
                            cb('Save');
                        }

                        return this;
                    }
                };
            }).and.callThrough(),
        alert: jasmine.createSpy(),
        success: jasmine.createSpy(),
        confirm: promiseMock.createSpy(),
        confirmDelete: promiseMock.createSpy(),
        info: jasmine.createSpy(),
        ieRequired: jasmine.createSpy(),
        empty: promiseMock.createSpy()
    };

    return r;
});