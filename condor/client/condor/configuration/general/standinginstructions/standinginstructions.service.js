angular.module('inprotech.configuration.general.standinginstructions').factory('StandingInstructionsService', function($http, ArrayExt, AssignedArray) {
    'use strict';

    function StandingInstructionsService() {
        this.saved = {
            characteristics: new ArrayExt(),
            instructions: new ArrayExt()
        };
    }

    function setId(array, data) {
        _.each(array, function(a) {
            a.oldId = a.id;
            var foundItem = _.find(data, {
                correlationId: a.id
            });
            a.id = foundItem ? foundItem.id : a.oldId;
        });
    }

    function getChar(array, id) {
        return _.find(array, function(a) {
            return a.id === id || a.correlationId === id;
        });
    }

    function setCharId(charArray, data) {
        if (!data || data.length === 0) {
            return;
        }
        _.each(charArray, function(ca) {
            var newChar = getChar(data, ca.id);
            if (newChar) {
                ca.id = newChar.id;
            }
        });
    }

    function setIds(instrType, data) {
        setId(instrType.characteristics.added, data.characteristics);
        setId(instrType.instructions.added, data.instructions);

        _.each(instrType.instructions.added, function(i) {
            setCharId(i.characteristics, data.characteristics);
        });

        _.each(instrType.instructions.updated, function(i) {
            setCharId(i.characteristics, data.characteristics);
        });
    }

    function setSavedForArray(array, savedArray) {
        _.each(array, function(i) {
            savedArray.pushOrGet('id', i.id).isSaved = true;
        });
    }

    function maintainSavedInstr(instr) {
        var instruction = this.saved.instructions.pushOrGet('id', instr.id);
        instruction.isSaved = true;

        if (!instruction.characteristics) {
            instruction.characteristics = new ArrayExt([]);
        }
        _.each(instr.characteristics, function(c) {
            instruction.characteristics.pushOrGet('id', c.id).isSaved = true;
        });
    }

    function maintainSavedItems(instrType) {
        var self = this;
        setSavedForArray(instrType.characteristics.updated, self.saved.characteristics);
        setSavedForArray(instrType.characteristics.added, self.saved.characteristics);

        _.each(instrType.instructions.added, function(i) {
            maintainSavedInstr.call(self, i);
        });

        _.each(instrType.instructions.updated, function(i) {
            maintainSavedInstr.call(self, i);
        });
    }

    function transform(response) {
        response.characteristics = new ArrayExt(response.characteristics);

        angular.forEach(response.instructions, function(item) {
            item.characteristics = new AssignedArray(item.characteristics);
        });
        response.instructions = new ArrayExt(response.instructions);

        return response;
    }

    function transformSavedData(response) {
        var self = this;

        response.characteristics.setSavedState(self.saved.characteristics, 'id');
        response.instructions.setSavedState(self.saved.instructions, 'id');
        _.each(response.instructions.items, function(i) {
            var savedInstr = _.find(self.saved.instructions.items, function(s) {
                return s.obj.id === i.obj.id;
            });
            if (savedInstr) {
                i.obj.characteristics.setSavedState(savedInstr.characteristics, 'id');
            }
        });
        return response;
    }

    StandingInstructionsService.prototype = {
        search: function(typeId) {
            this.saved = {
                characteristics: new ArrayExt(),
                instructions: new ArrayExt()
            };
            return $http.get('api/configuration/instructiontypedetails/' + typeId)
                .then(function(response) {
                    return transform(response.data);
                });
        },

        saveChanges: function(instrType, dataRetrived, errorOccured) {
            var self = this;
            return $http.post('api/configuration/instructiontypedetails/save', {
                instrType: instrType
            }).then(function(response) {
                if (response.data.result === 'success') {
                    if (dataRetrived) {
                        setIds(instrType, response.data.data);
                        maintainSavedItems.call(self, instrType);
                        dataRetrived(transformSavedData.call(self, transform.call(self, response.data.data)));
                    }
                    return true;
                } else {
                    if (errorOccured) {
                        errorOccured(response.data);
                    }
                    return false;
                }
            });
        }
    };
    return StandingInstructionsService;
});
