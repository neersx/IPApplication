angular.module('inprotech.mocks')
    .service('sponsorshipServiceMock', function() {
        'use strict';

        var r = {
            get: function() {
                return {
                    then: function(cb) {
                        return cb(r.get.returnValue);
                    }
                };
            },
            delete: function() {
                return {
                    then: function(cb) {
                        return cb(r.delete.returnValue);
                    }
                };
            },
            addOrUpdate: function() {
                return {
                    then: function(cb) {
                        return angular.extend({}, cb(r.addOrUpdate.returnValue), {
                            finally: function(cb) {
                                return cb();
                            }
                        });
                    }
                };
            },
            updateAccountSettings: function() {
                return {
                    then: function(cb) {
                        return angular.extend({}, cb(r.updateAccountSettings.returnValue), {
                            finally: function(f) {
                                return f();
                            }
                        });
                    }
                };
            }
        };

        Object.keys(r).forEach(function(key) {
            if (angular.isFunction(r[key])) {
                spyOn(r, key).and.callThrough();
            }
        });

        return r;
    });