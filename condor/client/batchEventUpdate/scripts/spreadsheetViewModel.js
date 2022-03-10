var batchEventUpdate = (function (my) {
    'use strict';

    my.spreadsheetViewModel = function (updatableCaseList, requiresPasswordConfirmation, newStatus, fileLocationList, criteriaId, dataEntryTaskId, dataEntryTaskFileLocationId, selectedCycle) {
        var m = application.windowViewModel('batch-event-update');

        var _updatableCases = ko.observable(ko.utils.arrayMap(updatableCaseList, function (updatableCase) {
            return batchEventUpdate.updatableCaseViewModel(updatableCase, dataEntryTaskFileLocationId);
        }));

        var _requiresConfirmation = function () {
            if (!m.newStatus()) {
                return false;
            }

            return _modifiedCases().any(function (modifiedCase) {
                return modifiedCase.CaseStatusDescription() !== m.newStatus();
            });
        };

        var _modifiedCases = function () {
            return m.updatableCases().where(function (c) {
                return (c.isInState([
                    caseState.loadedWithDefaults,
                    caseState.dirty,
                    caseState.reviewWarnings,
                    caseState.warningsReviewed,
                    caseState.errorsAndOrWarningsReviewed
                ]) && c.isSelected() === true);
            });
        };

        $.extend(m, {
            confirmOnSave: ko.observable(),
            requiresPasswordOnConfirmation: ko.observable(requiresPasswordConfirmation),
            validationResults: ko.observable(),
            newStatus: ko.observable(newStatus),
            showOnlyWarnings: ko.observable(false),
            showOnlyErrors: ko.observable(false),
            filterErrors: ko.observable(false),
            filterWarnings: ko.observable(false),
            fileLocations: ko.observable(fileLocationList)
        });

        m.updatableCases = utils.sortable(ko.computed(function () {
            var cases = _updatableCases();
            if (m.filterErrors() === false && m.filterWarnings() === false) {
                return cases;
            }

            var errorStates = [caseState.reviewErrorsAndOrWarnings, caseState.errorsAndOrWarningsReviewed];
            var warningStates = [caseState.reviewWarnings, caseState.warningsReviewed];

            return cases.where(function (c) {
                return (m.filterErrors() === true && c.isInState(errorStates)) ||
                    (m.filterWarnings() === true && c.isInState(warningStates));
            });
        }));

        m.saveMode = ko.computed({
            read: function () {
                var cases = _modifiedCases();

                if (!cases.any()) {
                    return saveMode.none;
                }

                if (cases.any(function (c) { return c.isInState([caseState.reviewWarnings]); })) {
                    return saveMode.acknowledgeWarningsAndSave;
                }

                return saveMode.save;
            }
        });

        m.firstCase = ko.computed(function () {
            return m.updatableCases().firstOrDefault();
        });

        m.applyChangesToAll = function (data, propertyName) {
            $.each(m.updatableCases(), function (index, c) {
                if (index === 0) {
                    return;
                }

                if (propertyName === 'FileLocationId') {
                    c.FileLocationId(m.updatableCases()[0].FileLocationId());
                    return;
                }

                if (propertyName === 'OfficialNumber') {
                    c.OfficialNumber(m.updatableCases()[0].OfficialNumber());
                    c.state(caseState.dirty);
                    return;
                }

                var event = c.AvailableEvents().single(function (e) { return e.EventId() === data.EventId(); });
                if (event[propertyName]() !== data[propertyName]()) {
                    event[propertyName](data[propertyName]());
                }
            });
        };

        var _handleResult = function (result) {
            m.filterErrors(false);
            m.filterWarnings(false);

            $.each(result, function (i, r) {
                _updatableCases().single(function (item) {
                    return r.CaseId === item.Id();
                }).update(r);
            });

            if (result.all(function (i) { return i.IsCompleted; })) {
                return { message: localise.getString('changesSaved') };
            }

            return { message: localise.getString('changedPartiallySaved') };
        };

        m.submitChanges = function () {
            if (_requiresConfirmation()) {
                m.confirmOnSave(batchEventUpdate.statusChangeConfirmationViewModel(_modifiedCases(),
                    criteriaId, dataEntryTaskId,
                    m.newStatus(), m.requiresPasswordOnConfirmation(), function (state) {
                        _handleResult(state.result);
                    }));
            } else {
                batchEventUpdate.saveCommand({
                    modifiedCases: _modifiedCases(),
                    criteriaId: criteriaId,
                    dataEntryTaskId: dataEntryTaskId,
                    actionCycle: selectedCycle,
                    then: _handleResult
                });
            }
        };

        m.currentCase = ko.computed(function () {
            return _updatableCases().firstOrDefault(function (c) {
                return c.isActive();
            });
        });

        return m;
    };

    return my;
}(batchEventUpdate || {}));
