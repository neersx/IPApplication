describe('ipWorkflowsEntryControlDefinition', function() {
    'use strict';

    var controller, extObjFactory;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        inject(function($componentController, ExtObjFactory) {
            extObjFactory = ExtObjFactory;
            controller = function(params) {
                var viewData = {
                    canEdit: true,
                    entryId: 1,
                    criteriaId: 2
                };
                _.extend(viewData, params);

                var c = $componentController('ipWorkflowsEntryControlDefinition', {}, {
                    topic: {
                        params: {
                            viewData: viewData
                        }
                    }
                });
                c.$onInit();
                return c;
            }
        });
    });

    describe('initialises', function() {
        var data;
        beforeEach(function() {
            data = {
                description: 'entry 1',
                userInstructions: 'instruct user',
                isInherited: true,
                parent: {
                    description: 'd',
                    userInstruction: 'u'
                }
            };
        });

        it('initialises', function() {
            var c = controller(data);

            expect(c.entryId).toBe(1);
            expect(c.canEdit).toBe(true);
            expect(c.parentData.description).toEqual('d');
            expect(c.parentData.userInstruction).toEqual('u');
        });

        it('fieldClasses should build ng-class', function() {
            var c = controller(data);
            var r = c.fieldClasses('description');
            expect(r).toBe('{edited: vm.formData.isDirty(\'description\')}');
        });

        it('hasError should only return true if invalid and dirty', function() {
            var c = controller(data);
            expect(dirtyCheck(c, true, true)).toBe(true);
            expect(dirtyCheck(c, false, true)).toBe(false);
            expect(dirtyCheck(c, true, false)).toBe(false);
            expect(dirtyCheck(c, false, false)).toBe(false);
        });
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
            description: 'description',
            userInstruction: 'user instructions'
        }
        var c = controller(data);
        expect(c.topic.getFormData().description).toEqual(data.description);
        expect(c.topic.getFormData().userInstruction).toEqual(data.userInstruction);
    });

    describe('state management', function() {
        var attachSpy, isDirtySpy, saveSpy, viewData;

        beforeEach(function() {
            viewData = {
                entryId: 1,
                criteriaId: 1, 
                canEdit: true,
                description: 'entry 1',
                userInstruction: 'instruct user'
            };
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
            controller(viewData);
            expect(attachSpy).toHaveBeenCalledWith(viewData);
        });

        it('returns dirty state from isDirty', function() {
            var c = controller(viewData);
            var result = c.topic.isDirty();
            expect(isDirtySpy).toHaveBeenCalled();
            expect(result).toBe('d');
        });
    });
});
