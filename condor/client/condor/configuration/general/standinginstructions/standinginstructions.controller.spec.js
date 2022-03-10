describe('inprotech.configuration.general.standinginstructions.StandingInstructionsController', function() {
    'use strict';

    var controller, ObjectExt, ArrayExt, AssignedArray, notificationService;

    beforeEach(function() {
        module('inprotech.configuration.general.standinginstructions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.standinginstructions', 'inprotech.mocks.components.notification']);
            $provide.value('StandingInstructionsService', $injector.get('StandingInstructionsServiceMock'));

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);
        });
    });

    beforeEach(inject(function($rootScope, $controller, _ObjectExt_, _ArrayExt_, _AssignedArray_) {
        ObjectExt = _ObjectExt_;
        ArrayExt = _ArrayExt_;
        AssignedArray = _AssignedArray_;

        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: $rootScope.$new()
            }, dependencies);

            var c = $controller('StandingInstructionsController', dependencies);
            c.form = {
                savable: function() {
                    return c.form.isSavable;
                },
                reset: function() {},
                setSavedValues: function() {}
            };

            return c;
        };
    }));

    describe('when initialised', function() {
        it('should create controller', function() {
            var c = controller();

            expect(c).toBeDefined();
        });

        it('should intialize data to blank', function() {
            var c = controller();

            expect(c.instrType).toBeDefined();
            expect(c.instrType.id).toBe(null);
            expect(_.isEmpty(c.selectedInstr)).toBe(true);
            expect(c.instrType.instructions.items.length).toBe(0);
            expect(c.instrType.characteristics.items.length).toBe(0);
        });
    });

    describe('when instruction type is selected', function() {
        var instructionType = {
            key: 'A'
        };

        it('should set type id for instruction pick list', function() {
            var c = controller();
            c.service.search.returnValue = {
                instructions: [{}, {}, {}, {}]
            };

            c.selectedInstrType = instructionType;
            c.typeChanged();

            expect(c.instrType.id).toEqual('A');
        });

        it('should call service to get details for selected instruction Type', function() {
            var c = controller();
            c.service.search.returnValue = {
                instructions: [{}, {}, {}, {}]
            };

            c.selectedInstrType = instructionType;
            c.typeChanged();

            expect(c.instrType.id).toEqual('A');
            expect(c.service.search).toHaveBeenCalledWith('A');
        });

        it('should set instructions, when instruction details are returned', function() {
            var c = controller();

            c.service.search.returnValue = {
                instructions: [{}, {}, {}, {}]
            };

            c.selectedInstrType = instructionType;
            c.typeChanged();

            expect(c.instrType.instructions.length).toEqual(4);
        });

        it('should set chacateristics, when instruction details are returned', function() {
            var c = controller();

            c.service.search.returnValue = {
                characteristics: [{}, {}, {}, {}]
            };

            c.selectedInstrType = instructionType;
            c.typeChanged();
            expect(c.instrType.characteristics.length).toEqual(4);
        });


        it('should clear instructions and characteristics when instructionType is cleared', function() {
            var c = controller();

            c.service.search.returnValue = {
                instructions: [{}, {}, {}, {}],
                characteristics: [{}, {}, {}, {}]
            };

            c.selectedInstrType = instructionType;
            c.typeChanged();
            expect(c.instrType.instructions.length).toEqual(4);
            expect(c.instrType.characteristics.length).toEqual(4);

            c.selectedInstrType = null;
            c.typeChanged();
            expect(c.instrType.id).toEqual(null);
            expect(c.instrType.instructions.items.length).toBe(0);
            expect(c.instrType.characteristics.items.length).toBe(0);
        });
    });

    describe('when instruction is selected', function() {
        var instruction;
        var instructionType = {
            key: 'A'
        };

        beforeEach(inject(function() {
            instruction = new ObjectExt({
                id: '1',
                characteristics: new AssignedArray()
            });
        }));

        it('should set selectedInstr', function() {
            var c = controller();
            c.form.isSavable = false;

            c.service.search.returnValue = {
                instructions: new ArrayExt([{
                    id: 1
                }]),
                characteristics: new AssignedArray([])
            };

            c.typeChanged(instructionType);
            c.selectInstruction(instruction);

            expect(c.selectedInstr).toEqual(instruction);
        });
    });

    describe('addition functionality', function() {
        it('should add new chacateristic', function() {
            var c = controller();
            c.instrType = {
                id: 1,
                characteristics: new ArrayExt()
            };
            c.addCharacteristics();

            expect(c.instrType.characteristics.items.length).toBe(1);
        });

        it('should add new addInstruction', function() {
            var c = controller();
            c.instrType = {
                id: 1,
                instructions: new ArrayExt(),
                characteristics: new ArrayExt()
            };
            c.addInstruction();

            expect(c.instrType.instructions.items.length).toBe(1);
        });
    });

    describe('assigned related functionality', function() {
        var instr, c;
        beforeEach(function() {
            instr = new ObjectExt({
                characteristics: []
            });
            instr.obj.characteristics = new AssignedArray([{
                id: 1,
                selected: false
            }, {
                id: 2,
                selected: true
            }]);

            c = controller();
            c.selectedInstr = instr;

            spyOn(c.selectedInstr, 'changeStatus');
            spyOn(c.selectedInstr.obj.characteristics, 'setValue');
            spyOn(c.selectedInstr.obj.characteristics, 'isUpdated');
            spyOn(c.selectedInstr.obj.characteristics, 'isSaved');
        });

        it('should call set Value for assigned array', function() {
            c.valueChangedAssignedChar({
                obj: {
                    id: 5,
                    selected: false
                }
            }, false);

            expect(c.selectedInstr.changeStatus).toHaveBeenCalledWith(false);
            expect(c.selectedInstr.obj.characteristics.setValue).toHaveBeenCalledWith(5, false, false);
        });

        it('should call set Value for assigned array, to revert the value', function() {
            c.valueChangedAssignedChar({
                obj: {
                    id: 5,
                    selected: true
                }
            }, true);

            expect(c.selectedInstr.obj.characteristics.setValue).toHaveBeenCalledWith(5, true, true);
        });

        it('should call isUpdated of assigned array', function() {
            c.isUpdated(1);

            expect(c.selectedInstr.obj.characteristics.isUpdated).toHaveBeenCalledWith(1);
        });

        it('should call isSaved of assigned array', function() {
            c.isSaved(10);

            expect(c.selectedInstr.obj.characteristics.isSaved).toHaveBeenCalledWith(10);
        });
    });

    describe('discard related functionality', function() {
        var instrType, c;
        beforeEach(function() {
            instrType = {
                instructions: new ArrayExt(),
                characteristics: new ArrayExt()
            };

            c = controller();
            c.instrType = instrType;

            spyOn(c.instrType.characteristics, 'revertAll');
            spyOn(c.instrType.instructions, 'revertAll');
            spyOn(c.form, 'reset');
        });

        it('should reset form if user selectes discard all on discard prompt', function() {
            c.discard();

            expect(c.form.reset).toHaveBeenCalled();
            expect(c.instrType.instructions.revertAll).toHaveBeenCalled();
            expect(c.instrType.characteristics.revertAll).toHaveBeenCalled();
        });
    });

    describe('save related functionality', function() {
        var instrType, c;
        beforeEach(function() {
            instrType = {
                instructions: [],
                characteristics: []
            };
            instrType.instructions = new ArrayExt();
            instrType.characteristics = new ArrayExt();

            c = controller();
            c.instrType = instrType;

            spyOn(c.instrType.characteristics, 'getChanges').and.returnValue({
                added: [],
                updated: [],
                deleted: []
            });
            spyOn(c.instrType.instructions, 'getChanges').and.returnValue({
                added: [],
                updated: [],
                deleted: []
            });
        });

        it('should get changed data from corresponding arrays', function() {
            c.save();

            expect(c.instrType.characteristics.getChanges).toHaveBeenCalled();
            expect(c.instrType.instructions.getChanges).toHaveBeenCalled();
        });

        it('should call service to save changes', function() {
            c.save();

            expect(c.service.saveChanges).toHaveBeenCalled();
        });
    });
});
