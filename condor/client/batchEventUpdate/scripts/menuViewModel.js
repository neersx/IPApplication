var batchEventUpdate = (function (my) {
    'use strict';

    my.menuViewModel = function (tempStorageId, confirmSelectionChange) {
        var m = {
            cases: ko.observable(null),
            openActions: ko.observable([]),
            shouldDisplayAllEntries: ko.observable(false),
            cycleSelection: ko.observable()
        };

        var _updateSelection = function (handlers) {

            var clearCasesAndAccept = function () {
                m.cases(null);
                handlers.accept();
            };

            if (!m.cases() || !confirmSelectionChange()) {
                clearCasesAndAccept();
                return;
            }

            dialogs.confirm({
                title: localise.getString('confirmTitle'),
                message: localise.getString('confirmUnsavedChanges'),
                type: 'warning',
                accept: clearCasesAndAccept,
                reject: handlers.reject || function () {
                }
            });
        };

        var _loadCases = function (criteriaId, dataEntryTaskId, useNextCycle, actionCycle) {
            httpClient.postJson('BatchEventUpdate/Events', {
                TempStorageId: tempStorageId,
                CriteriaId: criteriaId,
                DataEntryTaskId: dataEntryTaskId,
                UseNextCycle: useNextCycle == null ? '' : useNextCycle,
                ActionCycle: actionCycle
            }, {
                success: function (cases) {
                    m.cases(cases);
                },
                error: function (xhr) {
                    if (xhr.status !== utils.httpStatusCode.ambiguous) {
                        return false;
                    }

                    batchEventUpdate.cycleSelectionViewModel(tempStorageId, m.selectedAction().CriteriaId, m.selectedDataEntryTask().Id,
                        function (vm) {
                            m.cycleSelection(vm);
                        },
                        function () {
                            m.cycleSelection(null);
                        },
                        function (selection) {
                            _loadCases(m.selectedAction().CriteriaId, m.selectedDataEntryTask().Id, selection, m.selectedActionCycle());
                        });

                    return true;
                }
            });
        };

        m.showMatchingCases = function () {
            _updateSelection({
                accept: function () {
                    _loadCases(m.selectedAction().CriteriaId, m.selectedDataEntryTask().Id, null, m.selectedActionCycle());
                }
            });
        };

        m.selectedAction = ko.protectedObservable(null, _updateSelection);
        m.selectedDataEntryTask = ko.protectedObservable(null, _updateSelection);
        m.selectedActionCycle = ko.protectedObservable(null, _updateSelection);

        m.isSelectionValid = ko.computed(function () {
            if (m.selectedAction() && m.selectedDataEntryTask()) {
                return true;
            }
            else {
                return false;
            }
        });

        m.dataEntryTasks = ko.computed(function () {
            if (!m.selectedAction()) {
                return [];
            }

            return ko.utils.arrayFilter(m.selectedAction().DataEntryTasks, function (dataEntryTask) {
                return m.shouldDisplayAllEntries() || (!dataEntryTask.IsHidden);
            });
        });

        m.openCycles = ko.computed(function () {
            if (!m.selectedAction() || !m.selectedAction().IsCyclic) {
                return [];
            }

            return m.selectedAction().OpenCycles;
        });

        m.hasOpenCycles = ko.computed(function () {
            if (!m.selectedAction()) {
                return false;
            }

            return m.selectedAction().IsCyclic;
        });

        m.toggleAllEntries = function () {
            if (!m.selectedAction()) {
                return;
            }
            m.shouldDisplayAllEntries(!m.shouldDisplayAllEntries());
        };

        m.hasHiddenEntries = ko.computed(function () {
            if (!m.selectedAction()) {
                return false;
            }

            return m.selectedAction().DataEntryTasks.any(function (dataEntryTask) {
                return dataEntryTask.IsHidden === true;
            });
        });

        m.hasEntryInstructions = ko.computed(function () {
            if (!m.selectedDataEntryTask()) {
                return false;
            }
            return m.selectedDataEntryTask().UserInstruction !== null;
        });

        httpClient.json('BatchEventUpdate/menu/' + tempStorageId, function (data) {
            var actions = data.where(function (item) {
                return item.IsOpen;
            });

            m.openActions(actions);
        });

        return m;
    };
    return my;
}(batchEventUpdate || {}));
