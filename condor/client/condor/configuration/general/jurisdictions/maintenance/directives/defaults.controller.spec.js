describe('inprotech.configuration.general.jurisdictions.BillingDefaultsController', function() {
    'use strict';

    var controller, http, extObjFactory;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function() {
            var $injector = angular.injector(['inprotech.core.extensible']);
            extObjFactory = $injector.get('ExtObjFactory');

            http = test.mock('$http', 'httpMock');
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {
                    viewData: {
                        defaultCurrency: {},
                        defaultTaxRate: {},
                        isTaxNumberMandatory: false
                    }
                },
                $http: http,
                ExtObjFactory: extObjFactory
            }, dependencies);

            var c = $controller('BillingDefaultsController', dependencies, {
                topic: { canUpdate: true }
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialize', function() {
        it('get tax exempt options and initialize properties', function() {
            var expected = [{
                id: '0',
                description: 'Zero tax'
            }, {
                id: 'T0',
                description: 'Standard tax'
            }];

            http.get.returnValue = expected;

            var c = controller();

            expect(c.formData).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.discard).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();
            expect(c.topic.afterSave).toBeDefined();
            expect(c.topic.hasError).toBeDefined();
            expect(http.get).toHaveBeenCalled();
            expect(c.taxExemptOptions).toBe(expected);
        });
    });

    describe('topic', function() {
        it('hasError should only return true if invalid and dirty', function() {
            http.get.returnValue = {
                data: {}
            };

            var c = controller();

            expect(dirtyCheck(c, true, true)).toBe(true);
            expect(dirtyCheck(c, false, true)).toBe(false);
            expect(dirtyCheck(c, true, false)).toBe(false);
            expect(dirtyCheck(c, false, false)).toBe(false);
        });

        function dirtyCheck(c, invalid, dirty) {
            c.form = {
                $invalid: invalid,
                $dirty: dirty
            };
            return c.topic.hasError();
        }
    });
});