angular.module('inprotech.configuration.general.standinginstructions')
    .controller('StandingInstructionsController', function($scope, StandingInstructionsService, ArrayExt, AssignedArray, notificationService) {
        'use strict';

        var si = this;

        var service = new StandingInstructionsService();
        si.service = service;

        si.instrType = {};
        si.selectedInstr = {};

        var setInstrType = function() {
            si.instrType = {
                id: null,
                instructions: new ArrayExt([]),
                characteristics: new ArrayExt([])
            };
        };

        $scope.$watch('si.instrTypeForm.$invalid', function(invalid) {
            if (invalid) {
                setInstrType();
            } else if (si.selectedInstrType) {
                changeInstructiontype(si.selectedInstrType);
            }
        });

        si.typeChanged = function() {
            if ((!si.selectedInstrType || !si.selectedInstrType.key) && !si.form.savable()) {
                setInstrType();
                return;
            }
            if (si.selectedInstrType.key === si.instrType.id) {
                return;
            }
            changeInstructiontype(si.selectedInstrType);
        };

        var changeInstructiontype = function(selection) {
            si.selectedInstr = {};
            setInstrType();
            si.instrType.id = selection.key;
            if (si.instrType.id) {
                service.search(si.instrType.id)
                    .then(dataRetrived);
            }
        };

        var changeInstruction = function(instr) {
            si.selectedInstr = instr;
            if (!_.isEmpty(instr)) {
                si.selectedInstr.obj.characteristics.mergeByProperty(si.instrType.characteristics);
            }
        };

        si.selectInstruction = function(instr) {
            if (si.selectedInstr === instr) {
                return;
            }

            changeInstruction(instr);
        };

        si.addCharacteristics = function() {
            if (!si.instrType.id) {
                return;
            }
            var newId = si.instrType.characteristics.length() + 1;
            var newChar = {
                id: 'temp' + newId,
                description: ''
            };
            si.instrType.characteristics.addNew(newChar);
        };

        si.addInstruction = function() {
            if (!si.instrType.id) {
                return;
            }
            var newId = si.instrType.instructions.length() + 1;
            var newInstruction = {
                id: 'temp' + newId,
                description: '',
                characteristics: new AssignedArray([])
            };
            var newInstr = si.instrType.instructions.addNew(newInstruction);
            changeInstruction(newInstr);
        };

        si.valueChangedAssignedChar = function(characteristic, isReverted) {
            si.selectedInstr.changeStatus(false);
            si.selectedInstr.obj.characteristics.setValue(characteristic.obj.id, characteristic.obj.selected, isReverted);
        };

        si.isUpdated = function(id) {
            if (_.isEmpty(si.selectedInstr)) {
                return false;
            }
            return si.selectedInstr.obj.characteristics.isUpdated(id);
        };

        si.isSaved = function(id) {
            if (_.isEmpty(si.selectedInstr)) {
                return false;
            }

            return si.selectedInstr.obj.characteristics.isSaved(id);
        };

        si.discard = function() {
            discard();
        };

        var discard = function() {
            si.form.reset();
            si.instrType.characteristics.revertAll();
            si.instrType.instructions.revertAll();

            _.each(si.instrType.instructions.items, function(i) {
                i.obj.characteristics.revert();
            });

            changeInstruction(si.selectedInstr);
        };

        si.save = function() {
            var changedInstrType = {
                id: si.instrType.id,
                characteristics: [],
                instructions: []
            };

            changedInstrType.characteristics = si.instrType.characteristics.getChanges();
            changedInstrType.instructions = si.instrType.instructions.getChanges();

            var validCharIds = si.instrType.characteristics.getValidIds();

            _.each(changedInstrType.instructions.added, function(i) {
                i.characteristics.sanitize(validCharIds);
                var changes = i.characteristics.getChanges();
                i.characteristics = _.union(changes.updated, changes.added);
            });
            _.each(changedInstrType.instructions.updated, function(i) {
                i.characteristics.sanitize(validCharIds);
                var changes = i.characteristics.getChanges();
                i.characteristics = _.union(changes.updated, changes.added);
            });
            _.each(changedInstrType.instructions.deleted, function(i) {
                i.characteristics = [];
            });

            return si.service.saveChanges(changedInstrType, dataRetrived, errorWhileSaving);
        };

        var dataRetrived = function(data) {
            si.instrType.characteristics.clear();
            si.instrType.instructions.clear();
            si.instrType.characteristics = data.characteristics;
            si.instrType.instructions = data.instructions;
            si.form.setSavedValues();

            if (!_.isEmpty(si.selectedInstr)) {
                var selectedInstr = si.instrType.instructions.get('id', si.selectedInstr.obj.id);

                if (!selectedInstr) {
                    selectedInstr = si.instrType.instructions.get('correlationId', si.selectedInstr.obj.id);
                }
                changeInstruction(selectedInstr);
            }
        };

        var errorWhileSaving = function(errorData) {
            notificationService.alert(errorData);
            if (errorData.type === 'I') {
                si.instrType.instructions.setError(errorData.errors);
            } else if (errorData.type === 'C') {
                si.instrType.characteristics.setError(errorData.errors);
            }
        };

        si.resetUniquenessError = function(type, count) {
            _.each(_.range(count), function(i) {
                if (si.form[type + i].$error.isUnique) {
                    si.form[type + i].$validate();
                }
            });
        };

        si.UniqueInstruction = function(modelValue, viewValue) {
            return si.instrType.instructions.checkUniqueness('description', viewValue);
        };

        si.UniqueCharacteristic = function(modelValue, viewValue) {
            return si.instrType.characteristics.checkUniqueness('description', viewValue);
        };

        si.confirmDelete = function(o, type, index) {
            if (!o.isDeleted) {
                notificationService.confirm({
                    title: 'modal.markfordeletion.title',
                    message: 'modal.markfordeletion.message'
                }).then(function() {
                    o.delete();
                    si.form[type + index].markDeleted();
                    var count = 0;
                    if (type === 'char') {
                        count = si.instrType.characteristics.length();
                    } else {
                        count = si.instrType.instructions.length();
                    }
                    si.resetUniquenessError(type, count);
                });
            } else {
                o.delete();
                si.form[type + index].markDeleted(true);
            }
        };

        si.isDirty = function() {
            if (!si.form) {
                return false;
            }
            var assignedChanged = _.some(si.instrType.instructions.items, function(i) {
                return i.obj.characteristics.isDirty();
            }, true);
            return si.form.isDirty() || assignedChanged || si.instrType.instructions.anyAdditions() || si.instrType.characteristics.anyAdditions();
        };

        si.savable = function() {
            if (!si.form) {
                return false;
            }
            var assignedChanged = _.some(si.instrType.instructions.items, function(i) {
                return i.obj.characteristics.isDirty();
            }, true);
            var assignedSavable = assignedChanged && si.form.$valid;

            return si.form.savable() || assignedSavable;
        };

        si.getErrorText = function(o, type, index) {
            if (!si.form) {
                return '';
            }
            return o.getErrorText(si.form[type + index].$error);
        };

        setInstrType();
    });
