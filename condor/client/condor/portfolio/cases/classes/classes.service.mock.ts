angular.module('inprotech.mocks.portfolio.cases')
    .service('caseviewClassesServiceMock', () => {
        'use strict';

        let r = {
            getClassesSummary: () => {
                return {
                    then: (cb) => {
                        return cb(r.getClassesSummary);
                    }
                };
            },
            getClassTexts: function() {
                return {
                    then: function(cb) {
                        return cb(r.getClassTexts);
                    }
                };
            }
        };
        return r;
    });