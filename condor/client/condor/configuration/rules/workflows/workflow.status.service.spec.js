describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlChangeStatus', function() {
    'use strict';

    var service;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.validcombination']);
            $provide.value('ValidCombinationService', $injector.get('ValidCombinationServiceMock'));
        });

        inject(function(workflowStatusService) {
            service = workflowStatusService;
        });
    });

    describe('valid combination', function() {
        var characteristics = {
            jurisdiction: {
                key: 'au',
                value: 'australia'
            },
            caseType: {
                key: 'a',
                value: 'properties'
            },
            propertyType: {
                key: 'p',
                value: 'patent'
            }
        };

        it('should initialise characteristics valid status', function() {
            var c = service(characteristics);

            expect(c.validCombination.combination()).toEqual(['australia', 'properties', 'patent']);
        });

        it('should initialise characteritics for basic status', function() {
            var basicCharacteristics = {
                jurisdiction: {
                    key: 'au',
                    value: 'australia'
                },
                caseType: null,
                propertyType: null
            };
            var c = service(basicCharacteristics);
            expect(c.validCombination).toBe(null);
        });

        it('should initialise the service', function() {
            var c = service(characteristics);

            expect(c.addValidStatus).toEqual(jasmine.any(Function));
        });
    });

    describe('status query', function() {
        var query = {
            search: 'ab'
        };
        var characteristics = {
            jurisdiction: {
                key: 'au',
                value: 'australia'
            },
            caseType: {
                key: 'a',
                value: 'properties'
            },
            propertyType: {
                key: 'p',
                value: 'patent'
            }
        };

        it('should setup valid status query', function() {
            var c = service(characteristics);
            expect(c.validStatusQuery(query)).toEqual({
                caseType: 'a',
                jurisdiction: 'au',
                propertyType: 'p',
                search: 'ab'
            });
        });

        it('should setup case status query', function() {
            var c = service(characteristics);
            expect(c.caseStatusQuery(query)).toEqual({
                isRenewal: false,
                caseType: 'a',
                jurisdiction: 'au',
                propertyType: 'p',
                search: 'ab'
            });
        });

        it('should setup renewal status query', function() {
            var query = {
                search: 'ab'
            };
            var c = service(characteristics);
            expect(c.renewalStatusQuery(query)).toEqual({
                isRenewal: true,
                caseType: 'a',
                jurisdiction: 'au',
                propertyType: 'p',
                search: 'ab'
            });
        });

        it('should setup all renewal status query', function() {
            var query = {
                search: 'ab'
            };
            var c = service(characteristics);
            expect(c.allRenewalStatusQuery(query)).toEqual({
                search: 'ab',
                isRenewal: true
            });
        });

        it('should setup all case status query', function() {
            var query = {
                search: 'ab'
            };
            var c = service(characteristics);
            expect(c.allCaseStatusQuery(query)).toEqual({
                search: 'ab',
                isRenewal: false
            });
        });
    });
});