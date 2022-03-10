var batchEventUpdate = (function(my) {
    'use strict';

    my.updatableCaseViewModel = function(updatableCase, dataEntryTaskFileLocationId) {

        var updateState = function (newValue, oldValue) {
            if (m.state() === caseState.reviewWarnings){
                m.state(caseState.warningsReviewed);
            }
            else if (m.state() === caseState.reviewErrorsAndOrWarnings){
                m.state(caseState.errorsAndOrWarningsReviewed);
            }
            else {
                if (newValue === '' && !oldValue || oldValue === '' && !newValue){
                    return;
                }

                m.state(caseState.dirty);
            }
        };

        var mapping = {
            AvailableEvents: {
                create: function(options) {
                    return batchEventUpdate.availableEventViewModel(options.data);
                }
            }
        };

        var m = ko.mapping.fromJS(updatableCase, mapping);

        m.isActive = ko.observable(false);

        m.isInState = function (states) {
            return states.any(function (s) {
                return s === m.state();
            });
        };

        var validationResults = ko.observable([]);

        m.externalDataValidationResult = ko.observable();

        m.state = ko.observable(
            m.AvailableEvents().any(function(e) { return e.defaultDatesAreSet; }) ?
                caseState.loadedWithDefaults : caseState.loaded);

        var _isSelected = ko.observable(null);
        m.isSelected = ko.computed({
            read: function () {
                if (m.isInState([caseState.loaded, caseState.reviewErrorsAndOrWarnings, caseState.saved])) {
                    _isSelected(null);
                    return false;
                }

                if (_isSelected() !== null){
                    return _isSelected();
                }

                return true;
            },
            write: function (value) {
                _isSelected(value);
            }
        });

        m.disableSelectCheckBox = ko.computed(function() {
            return m.isInState([caseState.reviewErrorsAndOrWarnings, caseState.loaded, caseState.saved]);
        });

        $.each(m.AvailableEvents(), function(i, ae) {
            utils.koHelpers.subscribeToAny([m.OfficialNumber, ae.EventDate, ae.DueDate, ae.EventText, m.FileLocationId], updateState);
        });

        m.update = function(result) {

            validationResults(result.ValidationResults);

            if (result.IsCompleted) {
                m.state(caseState.saved);
                m.CaseStatusDescription(result.CaseStatusDescription);
                m.CurrentOfficialNumber(result.CurrentOfficialNumber);
                return;
            }

            if (result.ValidationResults.any(function(vr) { return vr.Severity === 'Error'; })) {
                m.state(caseState.reviewErrorsAndOrWarnings);
            }
            else if (result.ValidationResults.any(function (vr) { return vr.Severity === 'Warning'; })){
                m.state(caseState.reviewWarnings);
            }
            else{
                throw 'Unrecognized response received from server.';
            }
        };

        m.validationResults = ko.computed(function () {
            if (m.isInState([caseState.dirty, caseState.warningsReviewed, caseState.errorsAndOrWarningsReviewed])){
                return [];
            }

            if (m.isInState([caseState.saved])){
                return validationResults().where(function (vr) { return vr.Severity === 'Information'; });
            }

            return validationResults();
        });

        m.fieldValidationResults = function(inputName) {
            return m.validationResults().where(function(vr) {
                    return vr.Details.InputName === inputName;
                });
        };

        m.eventInputValidationResults = function (event, inputName) {
            return ko.computed(function () {
                return m.validationResults().where(function(vr) {
                    return vr.Details.EntityType === 'Event' &&
                        vr.Details.EntityId === event.EventId() &&
                        vr.Details.InputName === inputName;
                });
            });
        };

        var filterSanityCheckResults = function(source) {
            return source.where(function (vr) {
                return vr.Details.Name === 'SanityCheckResult';
            });
        };

        m.sanityCheckResults = ko.computed(function () {
            return filterSanityCheckResults(m.validationResults());
        });

        m.sanityCheckResultIds = function () {
            return m.validationResults().select(function(vr) {
                return vr.Details.CorrelationId;
            });
        };

        if(dataEntryTaskFileLocationId){
            m.FileLocationId(dataEntryTaskFileLocationId);
            m.state(caseState.dirty);
        }

        return m;
    };

    return my;
}(batchEventUpdate || {}));
