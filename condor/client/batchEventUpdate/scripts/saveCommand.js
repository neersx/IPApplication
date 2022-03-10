var batchEventUpdate = (function (my) {
    'use strict';
    my.saveCommand = function (options) {
        var cases = options.modifiedCases.select(function (modifiedCase) {
            var currentCase = sanitizeData(ko.mapping.toJS(modifiedCase));
            return {
                CaseId: currentCase.Id,
                ConfirmationPassword: options.passwordForStatusChange,
                ExternalDataValidationResult: modifiedCase.externalDataValidationResult(),
                ControllingCycle: currentCase.ControllingCycle,
                AreWarningsConfirmed: modifiedCase.state() === caseState.reviewWarnings,
                SanityCheckResultIds: modifiedCase.sanityCheckResultIds(),
                Data: [{
                    Key: 'batch-event-update',
                    Value: JSON.stringify({
                        Id: currentCase.Id,
                        OfficialNumber: currentCase.OfficialNumber,
                        AvailableEvents: currentCase.AvailableEvents,
                        FileLocationId: currentCase.FileLocationId,
                        WhenMovedToLocation: moment().format()
                    })
                }]
            };
        });

        httpClient.postJson('BatchEventUpdate/Save', {
            CriteriaId: options.criteriaId,
            DataEntryTaskId: options.dataEntryTaskId,
            Cases: cases,
            ActionCycle: options.actionCycle
        }, {
            success: options.then
        });
    };

    var sanitizeData = function (modifiedCase) {
        _.each(modifiedCase.AvailableEvents, function (a) {
            a = batchEventUpdate.availableEvent(a);
        });

        return modifiedCase;
    };

    return my;
}(batchEventUpdate || {}));