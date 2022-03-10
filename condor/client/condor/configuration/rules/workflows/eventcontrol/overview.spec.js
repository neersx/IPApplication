describe('ipWorkflowsEventControlOverview', function() {
    'use strict';

    var controller, extObjFactory, topic, http, modalService, promiseMock;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function(){
            var $injector = angular.injector(['inprotech.core.extensible']);
            extObjFactory = $injector.get('ExtObjFactory');

            http = test.mock('$http', 'httpMock');
            modalService = test.mock('modalService', 'modalServiceMock');
            promiseMock = test.mock('promise');
       });

        inject(function($componentController) {
            controller = function(viewData) {
                topic = {
                        params: {
                            viewData: _.extend({
                                eventId: 1,
                                overview: {
                                    data: {
                                        description: 'overview',
                                        setDirty: jasmine.createSpy()
                                    }
                                },
                                canEdit: true,
                                isInherited: true,
                                parent: {
                                    overview: {
                                        data: {
                                            'abc': 'def',
                                            maxCycles: 9999
                                        }
                                    }
                                }
                            }, viewData)
                        }
                    };
                
                var c = $componentController('ipWorkflowsEventControlOverview', {
                        ExtObjFactory: extObjFactory,
                        $http: http,
                        modalService: modalService
                     },
                    {topic: topic,
                    form: {
                        $invalid: false,
                        $dirty: false,
                        $reset: jasmine.createSpy(),

                        maxCycles :{
                            $setValidity: jasmine.createSpy()
                        }                        
                    }
                });
                c.$onInit();
                return c;
            }
        });
    });

    describe('initialisation', function() {
        it('initialises', function() {
            var c = controller({
                    overview:{
                        baseDescription: 'a',
                        importanceLevelOptions: ['a', 'b'],
                        data: {
                            description: 'overview'
                        }
                    }
               });

            expect(c.baseDescription).toBe('a');
            expect(c.importanceLevelOptions).toBe(topic.params.viewData.overview.importanceLevelOptions);
            expect(c.unlimitedCyclesChecked).toBeDefined();
            expect(c.maxCyclesChanged).toBeDefined();
            expect(c.isMaxCyclesDisabled).toBeDefined();

            expect(c.formData.description).toBe('overview');

            expect(c.eventId).toBe(1)
            expect(c.canEdit).toBe(true);
            expect(c.unlimitedCycles).toBeFalsy();

            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.discard).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();
            expect(c.topic.afterSave).toBeDefined();
            expect(c.parentData.abc).toEqual('def');
            expect(c.parentData.unlimitedCycles).toEqual(true);
        });

        it('checks unlimited cycles for 9999', function() {
            var c = controller({
                overview: {
                    data: {
                        maxCycles: 9999
                    }
                }});

            expect(c.unlimitedCycles).toBe(true);
        });
    });

    describe('state management', function() {
        var attachSpy, isDirtySpy, saveSpy;
        beforeEach(function() {
            attachSpy = jasmine.createSpy().and.returnValue(topic.params.viewData.overview.data);
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
            expect(attachSpy).toHaveBeenCalledWith(topic.params.viewData.overview.data);
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
    })

    describe('validation', function() {
        it('returns hasError if invalid and dirty', function() {
            var c = controller({dueDateCalcMaxCycles: 2});
            c.formData.maxCycles = 2;

            c.form.$invalid = false;
            c.form.$dirty = false;
            var hasError = c.topic.hasError();
            expect(hasError).toBe(false);

            c.form.$invalid = true;
            c.form.$dirty = false;
            hasError = c.topic.hasError();
            expect(hasError).toBe(false);

            c.form.$invalid = false;
            c.form.$dirty = true;
            hasError = c.topic.hasError();
            expect(hasError).toBe(false);

            c.form.$invalid = true;
            c.form.$dirty = true;
            hasError = c.topic.hasError();
            expect(hasError).toBe(true);
        });
    });

    describe('max cycles', function() {
        it('sets cycles to 9999 if unlimited cycles checked', function() {
            var c = controller();
            c.formData.maxCycles = 1;
            c.unlimitedCycles = true;
            c.unlimitedCyclesChecked();
            expect(c.formData.maxCycles).toBe(9999);
        });

        it('sets unlimited cycles if max cycles is greater than 9999', function() {
            var c = controller();
            c.formData.maxCycles = 10000;
            c.unlimitedCycles = false;

            c.maxCyclesChanged();
            expect(c.formData.maxCycles).toBe(9999);
            expect(c.unlimitedCycles).toBe(true);
        });

        it('disables max cycles field if cannot edit or unlimited cycles checked', function() {
            var c = controller();
            c.canEdit = false;
            c.formData.maxCycles = 1;
            var disabled = c.isMaxCyclesDisabled();
            expect(disabled).toBe(true);

            c.canEdit = true;
            c.unlimitedCycles = true;
            disabled = c.isMaxCyclesDisabled();
            expect(disabled).toBe(true);

            c.canEdit = true;
            c.unlimitedCycles = false;
            disabled = c.isMaxCyclesDisabled();
            expect(disabled).toBe(false);
        });
    });

    describe('discard method', function() {
        it('resets the form', function() {
            var attachSpy = jasmine.createSpy().and.returnValue(topic.params.viewData.overview);
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

    describe('getFormData method', function() {
        it('calls and returns getRaw', function() {
            var c = controller();
            c.formData.getRaw = jasmine.createSpy().and.returnValue('a');
            var result = c.topic.getFormData();
            expect(c.formData.getRaw).toHaveBeenCalled();
            expect(result).toBe('a');
        });
    });

    describe('isRespChanged', function() {
        var params, result, c;
        beforeEach(function() {
            c = controller();
            c.formData = {
                isDirty: function(key) {
                    return params[key];
                }
            };
        });

        it('should return true', function() {
            params = {
                name: true,
                nameType: false
            };
            result = c.topic.isRespChanged();
            expect(result).toEqual(true);
        });

        it('should return true', function() {
            params = {
                name: false,
                nameType: true
            };
            result = c.topic.isRespChanged();
            expect(result).toEqual(true);
        });

        it('should return false', function() {
            params = {
                name: false,
                nameType: false
            };
            result = c.topic.isRespChanged();
            expect(result).toEqual(false);
        });
    });

    describe('DueDate warning', function() {
        it('warn when due date cycles too high', function() {
            var c = controller({dueDateCalcMaxCycles: 3});

            c.formData.maxCycles = 2;

            var hasError = c.topic.hasError();
            expect(hasError).toBe(true);
            expect(c.form.maxCycles.$setValidity).toHaveBeenCalledWith(jasmine.any(String), false);
        });

        it('dont warn when due date cycles OK', function() {
            var c = controller({dueDateCalcMaxCycles: 2});

            c.formData.maxCycles = 2;

            var hasError = c.topic.hasError();
            expect(hasError).toBe(false);
            expect(c.form.maxCycles.$setValidity).toHaveBeenCalledWith(jasmine.any(String), true);
        });
    });

    describe('editing base event', function(){
        it('update fields when dont propagate', function(){
            http.get.returnValue = {data:{}};
            var c = controller();

            c.baseDescription = 'old desc';
            c.formData.maxCycles = 1;
            c.formData.importanceLevel = 'old';

            modalService.openModal = promiseMock.createSpy({
                description: 'new desc',
                maxCycles: 2,
                internalImportance: 'new',

                propagateChanges: false, // dont propagate to children
                updatedFields: [{id: 'maxCycles', updated: true}, {id: 'internalImportance', updated: true}]
            });

            c.onEditBaseEvent();

            expect(http.get).toHaveBeenCalled();
            expect(modalService.openModal).toHaveBeenCalled();

            expect(c.baseDescription).toBe('new desc'); // base description still applies regardless of 'dont propagate'
            expect(c.formData.maxCycles).toBe(1); // because of 'dont propagate' maxCycles should not be updated
            expect(c.formData.importanceLevel).toBe('old');
        });

        it('update fields when propagate', function(){
            http.get.returnValue = {data:{}};
            var c = controller();

            c.baseDescription = 'old desc';
            c.formData.maxCycles = 1;
            c.formData.importanceLevel = 'old';

            modalService.openModal = promiseMock.createSpy({
                description: 'new desc',
                maxCycles: 2,
                internalImportance: 'new',

                propagateChanges: true, // propagate to children
                updatedFields: [{id: 'maxCycles', updated: true}, {id: 'internalImportance', updated: true}]
            });

            c.onEditBaseEvent();

            expect(http.get).toHaveBeenCalled();
            expect(modalService.openModal).toHaveBeenCalled();

            expect(c.baseDescription).toBe('new desc');
            expect(c.formData.maxCycles).toBe(2);
            expect(c.formData.importanceLevel).toBe('new');
        });
    });

    describe('editing description', function(){
        it('enters baseDescription in description field, only if its empty, null or undefined', function() {
            var c = controller();

            c.baseDescription = 'old desc';

            c.formData.description = 'some description';
            c.ensureDescriptionIsNotEmpty();
            expect(c.formData.description).toBe('some description');

            c.formData.description = null;
            c.ensureDescriptionIsNotEmpty();
            expect(c.formData.description).toBe(c.baseDescription);

            c.formData.description = undefined;
            c.ensureDescriptionIsNotEmpty();
            expect(c.formData.description).toBe(c.baseDescription);

            c.formData.description = '';
            c.ensureDescriptionIsNotEmpty();
            expect(c.formData.description).toBe(c.baseDescription);

        });
    });
});
