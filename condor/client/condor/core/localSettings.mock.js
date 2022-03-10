angular.module('inprotech.mocks.core').factory('localSettingsMock', function() {
    'use strict';

    var r = {
        Keys: {
            caseImport: {
                status: {
                    pageNumber: {
                        getLocal: function() {
                            return r.Keys.caseImport.status.pageNumber.getLocal.returnValue;
                        },
                        setLocal: function(val) {
                            r.Keys.caseImport.status.pageNumber.getLocal.returnValue = val;
                        }
                    }
                },
                batchSummary: {
                    pageNumber: {
                        getLocal: function() {
                            return r.Keys.caseImport.batchSummary.pageNumber.getLocal.returnValue;
                        },
                        setLocal: function(val) {
                            r.Keys.caseImport.batchSummary.pageNumber.getLocal.returnValue = val;
                        }
                    }
                }
            },
            exchangeIntegration: {
                exchangeIntegrationQueue: {
                    pageNumber: {
                        getLocal: function() {
                            return r.Keys.exchangeIntegration.exchangeIntegrationQueue.pageNumber.getLocal.returnValue;
                        },
                        setLocal: function(val) {
                            r.Keys.exchangeIntegration.exchangeIntegrationQueue.pageNumber.getLocal.returnValue = val;
                        }
                    }
                }
            },
            caseView: {
                eFiling: {
                    pageNumber: {
                        getLocal: function() {
                            return r.Keys.caseView.eFiling.pageNumber.getLocal.returnValue;
                        },
                        setLocal: function(val) {
                            r.Keys.caseView.eFiling.pageNumber.getLocal.returnValue = val;
                        }
                    }
                }
            },
            policing: {
                savedRequests: {
                    pageNumber: {
                        getLocal: function() {
                            return r.Keys.caseView.eFiling.pageNumber.getLocal.returnValue;
                        },
                        setLocal: function(val) {
                            r.Keys.caseView.eFiling.pageNumber.getLocal.returnValue = val;
                        }
                    }
                }
            }
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        } else {
            if (Object.keys(r[key]).length > 0) {
                Object.keys(r[key]).forEach(function(key1) {
                    if (angular.isFunction(r[key][key1])) {
                        spyOn(r[key], key1).and.callThrough();
                    }
                });
            }
        }
    });

    return r;
});