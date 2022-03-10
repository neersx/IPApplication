describe('ipWorkflowsEventControlCharges', function() {
    'use strict';

    var controller, scope;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        inject(function($componentController, $rootScope) {
            controller = function(viewData) {
                scope = $rootScope.$new();
                scope.$emit = jasmine.createSpy();

                var c = $componentController('ipWorkflowsEventControlCharges', {
                    $scope: scope
                }, {
                    topic: {
                        params: {
                            viewData: viewData
                        },
                        key: 'charges',
                        isSubSection: true
                    }
                });
                c.$onInit();
                return c;
            }
        });
    });

    describe('initialise', function() {
        it('initialises', function() {
            var viewData = {
                canEdit: true,
                isInherited: true,
                parent: { charges: {} },
                charges: {}
            };

            var c = controller(viewData);
            expect(c.charges).toBe(viewData.charges);
            expect(c.canEdit).toEqual(true);
        });
        it('raise topicitemnumberscount event on $scope', function() {
            var viewData = {
                charges: {
                    chargeOne: {
                        chargeType: {}
                    },
                    chargeTwo: {
                        chargeType: null
                    }
                }
            };

            var c = controller(viewData);

            var expectedData = {
                key: 'charges',
                isSubSection: true,
                total: 1
            };
            expect(c.charges).toBe(viewData.charges);
            expect(scope.$emit).toHaveBeenCalledWith('topicItemNumbers', expectedData);
        });
    });

    describe('getFormData', function() {
        it('sends form data to server in correct format', function() {
            var c = controller({
                charges: {
                    chargeOne: {
                        chargeType: {
                            key: 'A'
                        },
                        isPayFee: true,
                        isRaiseCharge: true,
                        isEstimate: false,
                        isDirectPay: false
                    },
                    chargeTwo: {
                        chargeType: {
                            key: 'B'
                        },
                        isPayFee: false,
                        isRaiseCharge: false,
                        isEstimate: true,
                        isDirectPay: true
                    }
                }
            });

            var r = c.topic.getFormData();

            expect(r).toEqual({
                chargeType: 'A',
                isPayFee: true,
                isRaiseCharge: true,
                isEstimate: false,
                isDirectPay: false,

                chargeType2: 'B',
                isPayFee2: false,
                isRaiseCharge2: false,
                isEstimate2: true,
                isDirectPay2: true
            });
        });
    });

    describe('isInheritedMethod', function() {
        it('should return if charges are equal', function() {
            var c = controller({
                isInherited: true,
                parent: {
                    charges: {
                        'a': { 'abc': 'def' },
                        'b': 456
                    }
                },
                charges: {
                    'a': { 'abc': 'def' },
                    'b': 987
                }
            });
            var result = c.isInherited('a');
            expect(result).toEqual(true);

            result = c.isInherited('b');
            expect(result).toEqual(false);
        });
    });
});