describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlDisplayConditions', function() {
    'use strict';

    var controller, viewData, extObjFactory, topic, service;

    function setViewData(data) {
        viewData = {
            canEdit: true,
            entryId: 1,
            criteriaId: 2,
            isInherited: true,
            parent: {
                displayEvent: 'a',
                hideEvent: 'b',
                dimEvent: 'c'
            }
        };
        _.extend(viewData, data);
    }

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.components.grid', 'inprotech.mocks.configuration.rules.workflows', 'inprotech.core.extensible']);

            extObjFactory = $injector.get('ExtObjFactory');
            service = test.mock('workflowsEventControlService');
        });
    });

    beforeEach(inject(function($componentController) {
        controller = function(data) {
            setViewData(data);
            topic = {
                params: {
                    viewData: viewData
                }
            };

            var c = $componentController('ipWorkflowsEntryControlDisplayConditions', {
                ExtObjFactory: extObjFactory
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();

            expect(c.canEdit).toEqual(true);
            expect(c.formData.entryId).toBe(1);
            expect(c.topic.initialised).toEqual(true);

            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.discard).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();
            expect(c.topic.afterSave).toBeDefined();
            expect(service.initEventPicklistScope).toHaveBeenCalledWith({
                criteriaId: viewData.criteriaId,
                filterByCriteria: true
            });

            expect(c.parentData.displayEvent).toEqual('a');
            expect(c.parentData.hideEvent).toEqual('b');
            expect(c.parentData.dimEvent).toEqual('c');
        });
    });

    it('fieldClasses should build ng-class', function() {
        var c = controller();
        var r = c.fieldClasses('displayEventNo');
        expect(r).toBe('{edited: vm.formData.isDirty(\'displayEventNo\')}');
    });

    it('hasError should only return true if invalid and dirty', function() {
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

    it('getFormData should return correct data', function() {
        var data = {
            displayEvent: {
                key: 1
            },
            hideEvent: {
                key: 2
            },
            dimEvent: null
        }
        var c = controller(data);
        expect(c.topic.getFormData()).toEqual({
            displayEventNo: 1,
            hideEventNo: 2,
            dimEventNo: null
        });
    });

    describe('state management', function() {
        var attachSpy, isDirtySpy, saveSpy;
        beforeEach(function() {
            attachSpy = jasmine.createSpy().and.returnValue(viewData);
            isDirtySpy = jasmine.createSpy().and.returnValue('d');
            saveSpy = jasmine.createSpy().and.returnValue('s');

            var contextMock = {
                createContext: function() {
                    return {
                        attach: attachSpy,
                        isDirty: isDirtySpy,
                        save: saveSpy
                    }
                }
            };
            spyOn(extObjFactory.prototype, 'useDefaults').and.returnValue(contextMock);
        });

        it('attaches state observer', function() {
            controller();
            expect(attachSpy).toHaveBeenCalledWith(viewData);
        });

        it('returns dirty state from isDirty', function() {
            var c = controller();
            var result = c.topic.isDirty();
            expect(isDirtySpy).toHaveBeenCalled();
            expect(result).toBe('d');
        });

        it('saves state after save', function() {
            var c = controller();
            c.topic.afterSave();
            expect(saveSpy).toHaveBeenCalled();
        });
    });

    describe('discard method', function() {
        it('resets the form', function() {
            var attachSpy = jasmine.createSpy().and.returnValue(viewData);
            var restoreSpy = jasmine.createSpy();
            var contextMock = {
                createContext: function() {
                    return {
                        attach: attachSpy,
                        restore: restoreSpy
                    }
                }
            };
            spyOn(extObjFactory.prototype, 'useDefaults').and.returnValue(contextMock);

            var c = controller();

            c.form = {
                $reset: jasmine.createSpy()
            };

            c.topic.discard();

            expect(c.form.$reset).toHaveBeenCalled();
            expect(restoreSpy).toHaveBeenCalled();
        });
    });

    describe('validation for events', function() {
        var errorKey, attachSpy, form;
        beforeEach(function() {
            var data = {
                displayEvent: {
                    key: 1
                },
                hideEvent: {
                    key: 2
                },
                dimEvent: null
            };
            setViewData(data);

            attachSpy = jasmine.createSpy().and.returnValue(viewData);
            var restoreSpy = jasmine.createSpy();
            var contextMock = {
                createContext: function() {
                    return {
                        attach: attachSpy,
                        restore: restoreSpy
                    }
                }
            };
            spyOn(extObjFactory.prototype, 'useDefaults').and.returnValue(contextMock);
            var validitySpy = {
                $setValidity: jasmine.createSpy()
            };
            errorKey = 'entrycontrol.displayConditions.invalidcombination';
            form = {
                displayEventNo: validitySpy,
                hideEventNo: validitySpy,
                dimEventNo: validitySpy,
                $reset: jasmine.createSpy()
            };
        });

        it('clears error if value changed to null', function() {
            var c = controller();
            c.form = form;
            c.validate('dimEventNo');

            expect(c.form['dimEventNo'].$setValidity).toHaveBeenCalledWith(errorKey, null);
        });

        it('all unique should clear error for each', function() {
            var c = controller();
            c.form = form;
            c.validate('displayEventNo');

            expect(c.form['displayEventNo'].$setValidity).toHaveBeenCalledWith(errorKey, null);
            expect(c.form['hideEventNo'].$setValidity).toHaveBeenCalledWith(errorKey, null);
            expect(c.form['dimEventNo'].$setValidity).toHaveBeenCalledWith(errorKey, null);
        });

        it('should set error for duplicate value', function() {
            var data = {
                displayEvent: {
                    key: 1
                },
                hideEvent: {
                    key: 2
                },
                dimEvent: {
                    key: 1
                }
            };
            setViewData(data);
            attachSpy = jasmine.createSpy().and.returnValue(viewData);
            var c = controller();
            c.form = form;



            c.validate('dimEventNo');

            expect(c.form['dimEventNo'].$setValidity).toHaveBeenCalledWith(errorKey, false);
        });
    });

    describe('isInherited method', function() {
        it('compares display event, hide event, and dim event', function() {
            var c = controller();
            c.formData = _.clone(c.parentData);
            expect(c.isInherited()).toEqual(true);

            c.formData.displayEvent = 'x';
            expect(c.isInherited()).toEqual(false);

            c.formData.displayEvent = 'a';
            c.formData.hideEvent = 'x';
            expect(c.isInherited()).toEqual(false);
            
            c.formData.hideEvent = 'b';
            c.formData.dimEvent = 'x';
            expect(c.isInherited()).toEqual(false);

            c.formData.dimEvent = 'c';
            expect(c.isInherited()).toEqual(true);

            c.formData.displayEvent = {'abc': 'def'};
            c.parentData.displayEvent = {'abc': 'def'};
            expect(c.isInherited()).toEqual(true);
        });
    });
});