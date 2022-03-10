describe('ipWorkflowsEventControlStandingInstruction', function() {
    'use strict';

    var controller;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        inject(function($componentController) {
            controller = function(viewData) {
                var c = $componentController('ipWorkflowsEventControlStandingInstruction', {}, {
                    topic: {
                        params: {
                            viewData: _.extend({
                                canEdit: true,
                                isInherited: true,
                                parent: {
                                    standingInstruction: 'abc'
                                }
                            }, viewData)
                        }
                    },
                    form: {
                        instructionType :{
                            $setValidity: jasmine.createSpy()
                        }
                    }
                });
                c.$onInit();
                return c;
            }
        });
    });

    it('initialises', function() {
        var c = controller({
            standingInstruction: {
                instructionType: 'a',
                requiredCharacteristic: 'b',
                instructions: 'c',
                characteristicsOptions: 'd'
            }
        });

        expect(c.formData.instructionType).toEqual('a');
        expect(c.formData.requiredCharacteristic).toEqual('b');
        expect(c.instructions).toEqual('c');
        expect(c.characteristicsOptions).toEqual('d');
        expect(c.parentData).toEqual('abc');
    });

    it('displays instructions', function() {
        var c = controller({
            standingInstruction: {
                instructions: ['a', 'b']
            }
        });

        expect(c.displayInstructions()).toEqual('a; b');
    });

    it('characteristic field is required if instruction type is not empty', function() {
        var c = controller({
            standingInstruction: {
                instructionType: 'a'
            }
        });

        expect(c.isCharacteristicRequired()).toBe(true);

        c.formData.instructionType = null;

        expect(c.isCharacteristicRequired()).toBe(false);
    });

    it('characteristic field is disabled only instruction type is empty', function() {
        var c = controller({
            standingInstruction: {
                instructionType: 'a'
            }
        });

        expect(c.isCharacteristicDisabled()).toBe(false);

        c.formData.instructionType = null;

        expect(c.isCharacteristicDisabled()).toBe(true);
    });

    it('gets form data for save', function() {
        var c = controller({
            standingInstruction: {
                instructionType: {
                    code: 'a'
                },
                requiredCharacteristic: 'b'
            }
        });

        var formData = c.topic.getFormData();
        expect(formData).toEqual({
            instructionType: 'a',
            characteristic: 'b'
        });
    });

    describe('DueDate warning', function() {
        it('warn when due date depends on standing instruction', function() {
            var c = controller({
                standingInstruction: {
                    requiredCharacteristic: null
                },
                dueDateDependsOnStandingInstruction: true
            });

            var hasError = c.topic.hasError();
            expect(hasError).toBe(true);
            expect(c.form.instructionType.$setValidity).toHaveBeenCalledWith(jasmine.any(String), false);
        });

        it('dont warn when due date depends on standing instruction', function() {
            var c = controller({
                standingInstruction: {
                    requiredCharacteristic: 0
                },
                dueDateDependsOnStandingInstruction: true
            });

            var hasError = c.topic.hasError();
            expect(hasError).toBe(false);
            expect(c.form.instructionType.$setValidity).toHaveBeenCalledWith(jasmine.any(String), true);
        });
    });

    describe('isInherited method', function() {
        it('should compare form data with parent data', function() {
            var c = controller({
                standingInstruction: {
                    requiredCharacteristic: 'anything'
                },
                dueDateDependsOnStandingInstruction: true
            });
            c.formData = {'abc':'def'};
            c.parentData = _.clone(c.formData);
            expect(c.isInherited()).toEqual(true);

            c.formData.abc = 'xyz';
            expect(c.isInherited()).toEqual(false);
        })
    });
});
