var batchEventUpdate = (function (my) {
    'use strict';

    my.cycleSelectionViewModel = function (tempStorageId, criteriaId, dataEntryTaskId, onLoaded, cleanup, callBack) {
        var m = application.modalDialogViewModel();

        m = $.extend(m, {
            useNextCycle: ko.observable(null)
        });

        httpClient.postJson('BatchEventUpdate/CycleSelection', {
            TempStorageId: tempStorageId,
            CriteriaId: criteriaId,
            DataEntryTaskId: dataEntryTaskId
        }, {
            success: function (data) {
                var mapping = {
                    Events: {
                        create: function (options) {
                            var ev = ko.mapping.fromJS(options.data);
                            ev.DueDateFormatted = utilities.observableDate(options.data.DueDate);
                            ev.EventDateFormatted = utilities.observableDate(options.data.EventDate);
                            return ev;
                        }
                    }
                };

                m.firstCase = ko.mapping.fromJS(data, mapping);
                onLoaded(m);
            }
        });

        m.selectNextCycle = function () {
            m.useNextCycle(true);
            m.close();
        };

        m.selectCurrentCycle = function () {
            m.useNextCycle(false);
            m.close();
        };

        m.cancelCycleSelection = function () {
            m.close();
        };

        m.onClosedCallback = function () {
            cleanup();

            if (m.useNextCycle() !== null) {
                callBack(m.useNextCycle());
            }
        };

        return m;
    };
    return my;
}(batchEventUpdate || {}));
