describe('ipWorkflowsEventControlSyncEventDate', function() {
    'use strict';

    var controller;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        inject(function($componentController) {
            controller = function(viewData) {
                var ctrl = $componentController('ipWorkflowsEventControlSyncEventDate', {}, {
                    topic: {
                        params: {
                            viewData: viewData
                        }
                    }
                });
                ctrl.$onInit();
                ctrl.form = {
                    $setPristine: jasmine.createSpy(),
                    $setUntouched: jasmine.createSpy(),
                    caseOption: {
                        $setDirty: jasmine.createSpy()
                    }
                };

                return ctrl;
            }
        });
    });

    describe('initialise', function() {
        it('initialises vm', function() {
            var c = controller({
                criteriaId: 123,
                eventId: -11,
                canEdit: true,
                syncedEventSettings: {
                    caseOption: 'NotApplicable'
                }
            });

            expect(c.criteriaId).toBe(123);
            expect(c.eventId).toBe(-11);
            expect(c.canEdit).toBe(true);
            expect(c.caseOption).toBe('NotApplicable');
        });

        it('initialises model values for related case', function() {
            var c = controller({
                syncedEventSettings: {
                    caseOption: 'RelatedCase',
                    fromEvent: 11,
                    dateAdjustment: 'm',
                    fromRelationship: 5,
                    useCycle: 'CaseRelationship',
                    loadNumberType: 2
                }
            });

            expect(c.caseOption).toBe('RelatedCase');
            expect(c.relatedCase.fromEvent).toBe(11);
            expect(c.relatedCase.dateAdjustment).toBe('m');
            expect(c.relatedCase.fromRelationship).toBe(5);
            expect(c.relatedCase.useCycle).toBe('CaseRelationship');
            expect(c.relatedCase.loadNumberType).toBe(2);

            expect(c.sameCase.fromEvent).toBeUndefined();
            expect(c.sameCase.dateAdjustment).toBeUndefined();
        });

        it('initialises model values for same case', function() {
            var c = controller({
                syncedEventSettings: {
                    caseOption: 'SameCase',
                    fromEvent: 11,
                    dateAdjustment: 'm'
                }
            });

            expect(c.caseOption).toBe('SameCase');
            expect(c.sameCase.fromEvent).toBe(11);
            expect(c.sameCase.dateAdjustment).toBe('m');

            expect(c.relatedCase.fromEvent).toBeUndefined();
            expect(c.relatedCase.dateAdjustment).toBeUndefined();
            expect(c.relatedCase.fromRelationship).toBeUndefined();
            expect(c.relatedCase.loadNumberType).toBeUndefined();
        });

        it('sets use cycle to default for related case', function() {
            var c = controller({
                syncedEventSettings: {
                    caseOption: 'SameCase',
                    useCycle: 'CaseRelationship'
                }
            });

            expect(c.relatedCase.useCycle).toBe('RelatedCaseEvent');
        });

        describe('initialises eventPicklistScope', function() {
            it('sets filterByCriteria true for SameCase', function() {
                var c = controller({
                    criteriaId: 234,
                    syncedEventSettings: {
                        caseOption: 'SameCase'
                    }
                });

                expect(c.sameCaseEventPicklistScope.criteriaId).toBe(234);
                expect(c.sameCaseEventPicklistScope.filterByCriteria).toBe(false);
            });

            it('sets filterByCriteria false for RelatedCase', function() {
                var c = controller({
                    criteriaId: 234,
                    syncedEventSettings: {
                        caseOption: 'RelatedCase'
                    }
                });

                expect(c.relatedCaseEventPicklistScope.criteriaId).toBe(234);
                expect(c.relatedCaseEventPicklistScope.filterByCriteria).toBe(false);
            });
        });

        describe('initialise parent data', function() {
            it('initialises case option', function() {
                var c = controller({
                    criteriaId: 234,
                    syncedEventSettings: {
                        caseOption: 'RelatedCase'
                    },
                    isInherited: true,
                    parent: {
                        syncedEventSettings: {
                            caseOption: 'abc'
                        }
                    }
                });
                expect(c.parentData.caseOption).toEqual('abc');
            });

            it('initialises sameCase option', function() {
                var c = controller({
                    criteriaId: 234,
                    syncedEventSettings: {
                        caseOption: 'RelatedCase'
                    },
                    isInherited: true,
                    parent: {
                        syncedEventSettings: {
                            caseOption: 'SameCase',
                            fromEvent: {},
                            dateAdjustment: {}
                        }
                    }
                });
                expect(c.parentData.sameCase.fromEvent).toBeDefined();
                expect(c.parentData.sameCase.dateAdjustment).toBeDefined();
                expect(c.parentData.relatedCase.useCycle).toEqual('RelatedCaseEvent');
            });
            
            it('initialises relatedCase option', function() {
                var c = controller({
                    criteriaId: 234,
                    syncedEventSettings: {
                        caseOption: 'RelatedCase'
                    },
                    isInherited: true,
                    parent: {
                        syncedEventSettings: {
                            caseOption: 'RelatedCase',
                            fromEvent: {},
                            dateAdjustment: {},
                            fromRelationship: {},
                            loadNumberType: {},
                            useCycle: {}
                        }
                    }
                });
                expect(c.parentData.relatedCase.fromEvent).toBeDefined();
                expect(c.parentData.relatedCase.dateAdjustment).toBeDefined();
                expect(c.parentData.relatedCase.fromRelationship).toBeDefined();
                expect(c.parentData.relatedCase.loadNumberType).toBeDefined();
                expect(c.parentData.relatedCase.useCycle).toBeDefined();
            });
        });
    });

    describe('form', function() {
        var ctrl;
        beforeEach(function() {
            ctrl = controller({
                syncedEventSettings: {}
            });

            ctrl.form = {
                sameCase: {},
                relatedCase: {}
            }
            ctrl.caseOption = 'SameCase';
        });

        describe('getCurrentForm', function() {
            it('returns sameCase form', function() {
                ctrl.caseOption = 'SameCase';
                expect(ctrl.getCurrentForm()).toBe(ctrl.form.sameCase);
            });

            it('returns relatedCase form', function() {
                ctrl.caseOption = 'RelatedCase';
                expect(ctrl.getCurrentForm()).toBe(ctrl.form.relatedCase);
            });
        });

        describe('hasError', function() {
            it('returns true if current form invalid', function() {
                ctrl.form.sameCase.$invalid = true;
                expect(ctrl.topic.hasError()).toBe(true);
            });

            it('returns false if current form valid', function() {
                ctrl.form.sameCase.$invalid = false;
                expect(ctrl.topic.hasError()).toBe(false);
            });
        });

        describe('isDirty', function() {
            it('returns form dirty flag', function() {
                ctrl.form.$dirty = 'dirtyFlag';
                expect(ctrl.topic.isDirty()).toBe('dirtyFlag');
            });
        });

        describe('getFormData', function() {
            it('returns save model for sameCase', function() {
                ctrl.sameCase = {
                    fromEvent: {
                        key: 111
                    },
                    dateAdjustment: 3
                };

                expect(ctrl.topic.getFormData()).toEqual({
                    caseOption: 'SameCase',
                    fromEvent: 111,
                    dateAdjustment: 3
                });
            });

            it('returns save model for relatedCase', function() {
                ctrl.caseOption = 'RelatedCase';

                ctrl.relatedCase = {
                    useCycle: 'yes',
                    fromEvent: {
                        key: 111
                    },
                    fromRelationship: {
                        key: 222
                    },
                    loadNumberType: {
                        key: 333
                    },
                    dateAdjustment: 3
                };

                expect(ctrl.topic.getFormData()).toEqual({
                    caseOption: 'RelatedCase',
                    useCycle: 'yes',
                    fromEvent: 111,
                    fromRelationship: 222,
                    loadNumberType: 333,
                    dateAdjustment: 3
                });

            });
        });

        describe('validate', function() {
            it('returns true for NotApplicable', function() {
                ctrl.caseOption = 'NotApplicable';
                expect(ctrl.topic.validate()).toBe(true);
            });

            it('calls correct form validate', function() {
                ctrl.form.sameCase = {
                    $validate: jasmine.createSpy()
                };

                ctrl.topic.validate();
                expect(ctrl.form.sameCase.$validate).toHaveBeenCalled();
            });
        });
    });
    
    describe('isInherited method', function() {
        it('should compare form data with parent data', function() {
            var c = controller({
                criteriaId: 234,
                syncedEventSettings: {
                    caseOption: 'RelatedCase'
                }
            });
            c.parentData.caseOption = c.caseOption;
            c.sameCase = 'a';
            c.parentData.sameCase = 'a'
            c.relatedCase = 'b';
            c.parentData.relatedCase = 'b'
            expect(c.isInherited()).toEqual(true);

            c.parentData.caseOption = 'something else';
            expect(c.isInherited()).toEqual(false);
            
            c.parentData.caseOption = c.caseOption;
            c.sameCase = 'x';
            expect(c.isInherited()).toEqual(false);
            
            c.sameCase = 'a';
            c.relatedCase = 'x';
            expect(c.isInherited()).toEqual(false);

            c.relatedCase = 'b'
            expect(c.isInherited()).toEqual(true);
        })
    });
});
