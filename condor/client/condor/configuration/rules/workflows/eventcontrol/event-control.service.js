angular.module('inprotech.configuration.rules.workflows').factory('workflowsEventControlService', function($http, $translate) {
    'use strict';

    var relativeCycles = [{
        key: 0,
        value: 'workflows.eventcontrol.relativeCycleMap.currentCycle',
        showAll: true
    }, {
        key: 1,
        value: 'workflows.eventcontrol.relativeCycleMap.previousCycle',
        showAll: true
    }, {
        key: 2,
        value: 'workflows.eventcontrol.relativeCycleMap.nextCycle',
        showAll: true
    }, {
        key: 3,
        value: 'workflows.eventcontrol.relativeCycleMap.cycle1',
        showAll: true
    }, {
        key: 4,
        value: 'workflows.eventcontrol.relativeCycleMap.highestCycle',
        showAll: true
    }, {
        key: 5,
        value: 'workflows.eventcontrol.relativeCycleMap.all',
        showAll: false
    }, {
        key: 6,
        value: 'workflows.eventcontrol.relativeCycleMap.allLower',
        showAll: false
    }, {
        key: 7,
        value: 'workflows.eventcontrol.relativeCycleMap.allHigher',
        showAll: false
    }];

    var periodTypesShort = [{
        key: 'D',
        value: 'periodTypes.days'
    }, {
        key: 'W',
        value: 'periodTypes.weeks'
    }, {
        key: 'M',
        value: 'periodTypes.months'
    }, {
        key: 'Y',
        value: 'periodTypes.years'
    }];

    var periodTypes = periodTypesShort.concat([{
        key: 'E',
        value: 'workflows.eventcontrol.dueDateCalc.periodTypeMap.entered'
    }, {
        key: '1',
        value: 'workflows.eventcontrol.dueDateCalc.periodTypeMap.period1'
    }, {
        key: '2',
        value: 'workflows.eventcontrol.dueDateCalc.periodTypeMap.period2'
    }, {
        key: '3',
        value: 'workflows.eventcontrol.dueDateCalc.periodTypeMap.period3'
    }]);

    var nonWorkDayOptions = [{
        key: 0,
        value: 'workflows.eventcontrol.dueDateCalc.nonWorkDayMap.ok'
    }, {
        key: 1,
        value: 'workflows.eventcontrol.dueDateCalc.nonWorkDayMap.nextWorkDayAfter'
    }, {
        key: 2,
        value: 'workflows.eventcontrol.dueDateCalc.nonWorkDayMap.lastWorkDayBefore'
    }];

    var operators = [{
        key: "<",
        value: "<"
    }, {
        key: "<=",
        value: "<="
    }, {
        key: "<>",
        value: "<>"
    }, {
        key: "=",
        value: "="
    }, {
        key: ">",
        value: ">"
    }, {
        key: ">=",
        value: ">="
    }, {
        key: "EX",
        value: $translate.instant('operators.exists')
    }, {
        key: "NE",
        value: $translate.instant('operators.notExists')
    }];

    var dateLogicOperators = [{
        key: "<",
        value: "<"
    }, {
        key: "<=",
        value: "<="
    }, {
        key: "<>",
        value: "<>"
    }, {
        key: "=",
        value: "="
    }, {
        key: ">",
        value: ">"
    }, {
        key: ">=",
        value: ">="
    }];

    var relativeCycleMap = _.object(_.map(relativeCycles, function(item) {
        return [item.key, item.value];
    }));

    var periodTypeMap = _.object(_.map(periodTypes, function(item) {
        return [item.key, item.value];
    }));

    return {
        getMatchingNameTypes: getMatchingNameTypes,
        getDateComparisons: getDateComparisons,
        getSatisfyingEvents: getSatisfyingEvents,
        getDesignatedJurisdictions: getDesignatedJurisdictions,
        getDateLogicRules: getDateLogicRules,
        getEventsToClear: getEventsToClear,
        translateRelativeCycle: translateRelativeCycle,
        getEventsToUpdate: getEventsToUpdate,
        getReminders: getReminders,
        translatePeriodType: translatePeriodType,
        getDocuments: getDocuments,
        translateProduce: translateProduce,
        relativeCycles: relativeCycles,
        periodTypes: periodTypes,
        periodTypesShort: periodTypesShort,
        nonWorkDayOptions: nonWorkDayOptions,
        updateEventControl: updateEventControl,
        operators: operators,
        dateLogicOperators: dateLogicOperators,
        translateOperator: translateOperator,
        isDuplicated: isDuplicated,
        hasDuplicate: hasDuplicate,
        isApplyEnabled: isApplyEnabled,
        getUsedInInstructions: getUsedInInstructions,
        getCharacteristicOptions: getCharacteristicOptions,
        mapGridDelta: mapGridDelta,
        initEventPicklistScope: initEventPicklistScope,
        formatPicklistColumn: formatPicklistColumn,
        formatEventNo: formatEventNo,
        findLastDuplicate: findLastDuplicate,
        getDefaultRelativeCycle: getDefaultRelativeCycle,
        setEditedAddedFlags: setEditedAddedFlags,
        resetEvent: resetEvent,
        breakEventInheritance: breakEventInheritance
    };

    function translateProduce(produce) {
        var produceMap = {
            1: 'workflows.eventcontrol.documents.onDueDate',
            2: 'workflows.eventcontrol.documents.eventOccurs'
        };

        return produce == null ? 'workflows.eventcontrol.documents.recurring' : produceMap[produce];
    }

    function translateRelativeCycle(relativeCycle) {
        if (relativeCycle == null) {
            return relativeCycle;
        }

        return $translate.instant(relativeCycleMap[relativeCycle]);
    }

    function translatePeriodType(periodType) {
        if (periodType == null) {
            return periodType;
        }

        return periodTypeMap[periodType];
    }

    function translateOperator(op) {
        if (op == null) return;

        if (op.key === 'EX') {
            op.value = $translate.instant('operators.exists');
        } else if (op.key === 'NE') {
            op.value = $translate.instant('operators.notExists');
        } else {
            op.value = op.key;
        }
    }

    function initEventPicklistScope(picklistScope) {
        return _.extend(picklistScope, {
            extendQuery: function(query) {
                if (picklistScope.filterByCriteria) {
                    return angular.extend({}, query, {
                        criteriaId: picklistScope.criteriaId,
                        picklistSearch: picklistScope.picklistSearch
                    });
                }
                return angular.extend({}, query, {
                    criteriaId: !picklistScope.picklistSearch
                        ? picklistScope.criteriaId
                        : null,
                    picklistSearch: picklistScope.picklistSearch
                });
            }
        });
    }

    function formatPicklistColumn(picklist) {
        if (!picklist) {
            return '';
        }

        return picklist.value + ' (' + picklist.key + ')';
    }

    function getMatchingNameTypes(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/nametypemaps')
            .then(function(response) {
                return response.data;
            });
    }

    function getDateComparisons(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/datecomparisons')
            .then(function(response) {
                return response.data;
            });
    }

    function getSatisfyingEvents(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/satisfyingevents')
            .then(function(response) {
                return response.data;
            });
    }

    function getDesignatedJurisdictions(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/designatedjurisdictions')
            .then(function(response) {
                return response.data;
            });
    }

    function getDateLogicRules(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/dateslogic')
            .then(function(response) {
                return response.data;
            });
    }

    function getEventsToClear(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/eventstoclear')
            .then(function(response) {
                return response.data;
            });
    }

    function getEventsToUpdate(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/eventstoupdate')
            .then(function(response) {
                return response.data;
            });
    }

    function getReminders(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/reminders')
            .then(function(response) {
                return response.data;
            });
    }

    function getDocuments(criteriaId, eventId) {
        return $http.get(getApiPrefix(criteriaId, eventId) + '/documents')
            .then(function(response) {
                return response.data;
            });
    }

    function updateEventControl(criteriaId, eventId, formData) {
        var url = getApiPrefix(criteriaId, eventId);

        return $http.put(url, formData).then(function(response) {
            return response.data;
        });
    }

    function getUsedInInstructions(charateristicId) {
        return $http.get('api/configuration/rules/workflows/eventcontrol/characteristics/' + encodeURIComponent(charateristicId) + '/usedin')
            .then(function(response) {
                return response.data;
            });
    }

    function getCharacteristicOptions(instructionTypeCode) {
        return $http.get('api/configuration/rules/workflows/eventcontrol/instructionTypes/' + encodeURIComponent(instructionTypeCode) + '/characteristics')
            .then(function(response) {
                return response.data;
            });
    }

    function isDuplicated(allRecords, currentRecord, propList) {
        var exists = _.any(_.without(allRecords, currentRecord), function(r) {
            return _.all(propList, function(p) {
                return equals(r[p], currentRecord[p]);
            });
        });

        return exists;
    }

    function hasDuplicate(allRecords, propList) {
        allRecords = _.filter(allRecords, function(item) {
            return item.deleted ? false : true;
        });

        for (var i = allRecords.length - 1; i >= 0; i--) {
            var exists = isDuplicated(_.without(allRecords, allRecords[i]), allRecords[i], propList);
            if (exists) {
                allRecords[i].isDuplicatedRecord = true;
                return true;
            }
        }
        return false;
    }

    function findLastDuplicate(allRecords, propList) {
        allRecords = _.filter(allRecords, function(item) {
            return item.deleted ? false : true;
        });

        for (var i = allRecords.length - 1; i >= 0; i--) {
            var exists = isDuplicated(_.without(allRecords, allRecords[i]), allRecords[i], propList);
            if (exists) {
                return allRecords[i];
            }
        }

        return null;
    }

    function equals(v1, v2) {
        if ((v1 && v2) || (v1 && v2) === 0) {
            if ((v1.key && v2.key) || (v1.key && v2.key) === 0) {
                return equals(v1.key, v2.key);
            }

            if (v1.value && v1.type && v2.value && v2.type) {
                return equals(v1.value, v2.value) && equals(v1.type, v2.type);
            }
        }

        if (v2 instanceof Date) {
            v1 = new Date(v1);
        }

        return normalize(v1) === normalize(v2);
    }

    function normalize(value) {
        if (value === '' || value == null) {
            return null;
        }

        if (value instanceof Date) {
            return Number(value);
        }

        return value;
    }

    function isApplyEnabled(angularForm) {
        return !angularForm.$pristine && !angularForm.$invalid;
    }

    function mapGridDelta(data, mapFunc) {
        return {
            added: _.chain(data).filter(isAdded).map(mapFunc).value(),
            deleted: _.chain(data).filter(isDeleted).map(mapFunc).value(),
            updated: _.chain(data).filter(isUpdated).map(mapFunc).value()
        };
    }

    function isAdded(data) {
        return (data.added || data.isAdded) && !data.deleted;
    }

    function isDeleted(data) {
        return data.deleted;
    }

    function isUpdated(data) {
        return (data.isEdited || data.isDirty && data.isDirty()) && !data.deleted && !(data.added || data.isAdded);
    }

    function formatEventNo(evt) {
        return evt ? evt.key : '';
    }

    function getDefaultRelativeCycle(evt) {
        if (evt) {
            if (evt.maxCycles == 1) {
                return 3;
            } else {
                return 0;
            }
        }

        return null;
    }

    function setEditedAddedFlags(data, isEditMode) {
        if (isEditMode && !data.isAdded) {
            data.isEdited = true;
            data.inherited = false;
        } else {
            data.isAdded = true;
        }
    }

    function resetEvent(criteriaId, eventId, applyToDescendants, updateNameResponsible) {
        var url = getApiPrefix(criteriaId, eventId) + '/reset?applyToDescendants=' + applyToDescendants;

        if (updateNameResponsible != null) {
            url += '&updateRespNameOnCases=' + updateNameResponsible;
        }

        return $http.put(url).then(function(response) {
            return response.data;
        });
    }

    function breakEventInheritance(criteriaId, eventId) {
        var url = getApiPrefix(criteriaId, eventId) + '/break';

        return $http.put(url).then(function(response) {
            return response.data;
        });
    }

    function getApiPrefix(criteriaId, eventId) {
        return 'api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/eventcontrol/' + encodeURIComponent(eventId);
    }
});