describe('inprotech.configuration.rules.workflows.ipSearchByCaseController', function() {
    'use strict';

    var controller, workflowsSearchService, charsService, scope;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.rules.workflows']);
            workflowsSearchService = $injector.get('workflowsSearchServiceMock');
            $provide.value('workflowsSearchService', workflowsSearchService);
            charsService = $injector.get('workflowsCharacteristicsServiceMock');
            $provide.value('workflowsCharacteristicsService', charsService);
        });

        inject(function($controller) {
            controller = function() {
                var c = $controller('ipSearchByCaseController', {
                    $scope: scope
                });
                c.$onInit();
                c.formData = {};
                c.form = {};
                return c;
            };
        });
    });

    describe('initialisation', function() {
        it('should initialise controller', function() {
            var c = controller();

            expect(c.selectCase).toBeDefined();
            expect(c.handleActionSelected).toBeDefined();

            expect(charsService.initController).toHaveBeenCalledWith(c, 'case', {
                applyTo: null,
                matchType: 'best-criteria-only'
            });

            expect(c.selectCase).toBeDefined();
        });
    });

    describe('Selecting a case', function() {
        var selectedCase, chars;
        beforeEach(function() {
            selectedCase = {
                key: 'key'
            };
            chars = {
                item: 'a'
            };
            workflowsSearchService.getCaseCharacteristics.returnValue = chars;
        });

        it('Forwards correct parameters', function() {
            var c = controller();
            c.formData.case = selectedCase;

            c.selectCase();

            expect(workflowsSearchService.getCaseCharacteristics).toHaveBeenCalledWith(c.formData.case.key);
            expect(c.formData.item).toBe('a');
        });

        it('Resets all characteristics fields except action', function() {
            var c = controller();
            c.formData.case = selectedCase;

            var resetSpyFn = jasmine.createSpy('resetSpy');
            charsService.characteristicFields = ['a', 'b', 'action'];
            _.each(charsService.characteristicFields, function(field) {
                c.form[field] = {
                    $reset: resetSpyFn
                };
            });

            var notCalledSpyFn = jasmine.createSpy('notCalledSpy');
            c.form.nonCharacteristicField = {
                $reset: notCalledSpyFn
            };

            c.selectCase();

            expect(resetSpyFn.calls.count()).toBe(charsService.characteristicFields.length - 1);
            expect(notCalledSpyFn).not.toHaveBeenCalled();
        });

        it('sets default date of law when action already selected', function() {
            var c = controller();
            c.formData.case = selectedCase;

            c.formData.action = {
                code: 'itemKey',
                value: 'itemValue'
            };

            workflowsSearchService.getDefaultDateOfLaw.returnValue = {
                key: 'resultKey',
                value: 'resultValue'
            };

            c.selectCase();

            expect(workflowsSearchService.getDefaultDateOfLaw).toHaveBeenCalledWith(c.formData.case.key, c.formData.action.code);
            expect(c.formData.dateOfLaw).toEqual({
                key: 'resultKey',
                value: 'resultValue'
            });
        });
    });

    it('sets default date of law when action selected', function() {
        var c = controller();
        c.formData.case = {
            key: 'caseKey'
        };
        c.formData.action = {
            code: 'itemKey',
            value: 'itemValue'
        };

        workflowsSearchService.getDefaultDateOfLaw.returnValue = {
            key: 'resultKey',
            value: 'resultValue'
        };

        c.handleActionSelected();

        expect(workflowsSearchService.getDefaultDateOfLaw).toHaveBeenCalledWith(c.formData.case.key, c.formData.action.code);
        expect(c.formData.dateOfLaw).toEqual({
            key: 'resultKey',
            value: 'resultValue'
        });
    });
});