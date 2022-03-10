var batchEventUpdate = (function (my) {
    'use strict';

    my.appViewModel = function (tempStorageId) {
        var _hasUnsavedChanges = function () {
            var saveModes = [saveMode.save, saveMode.acknowledgeWarningsAndSave];
            return m.currentView() && saveModes.any(function (mode) { return m.currentView().saveMode() === mode; });
        };

        var _menu = batchEventUpdate.menuViewModel(tempStorageId, _hasUnsavedChanges);

        var m = $.extend(application.appBaseViewModel(), {
            menu: ko.observable(_menu),
            nonUpdatableCases: utils.sortable([])
        });

        _menu.cases.subscribe(function (newValue) {
            if (!newValue) {
                m.currentView(null);
                m.nonUpdatableCases([]);
                return;
            }

            m.nonUpdatableCases(newValue.NonUpdatableCases.select(function (item) {
                return batchEventUpdate.nonUpdatableCaseViewModel(item);
            }));

            m.currentView(batchEventUpdate.spreadsheetViewModel(newValue.UpdatableCases,
                newValue.RequiresPasswordOnConfirmation,
                newValue.NewStatus,
                newValue.FileLocations,
                _menu.selectedAction().CriteriaId,
                _menu.selectedDataEntryTask().Id,
                _menu.selectedDataEntryTask().FileLocationId,
                _menu.selectedActionCycle()));
        });

        m.logout = batchEventUpdate.logout;

        return m;
    };
    return my;
}(batchEventUpdate || {}));
