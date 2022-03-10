var batchEventUpdate = (function (my) {
    'use strict';

    my.validationResultsViewModel = function (validationResults) {
        var m = {
            results: ko.observable(!validationResults ? [] : validationResults)
        };

        m.hasWarnings = function () {
            return m.results().any(function (value) {
                return value.IsWarning;
            });
        };

        m.hasErrors = function () {
            return m.results().any(function (value) {
                return !value.IsWarning;
            });
        };

        m.hasErrorsOrWarnings = function() {
            return m.hasAnyWarnings() || m.hasAnyErrors();
        };

        m.hasOnlyWarnings = function () {
            return !m.hasAnyErrors() && m.hasAnyWarnings();
        };

        m.hasCorrelatedWarnings = function (correlationId) {
            return m.results().any(function (value) {
                return value.IsWarning && value.CorrelationId === correlationId;
            });
        };

        m.hasCorrelatedErrors = function (correlationId) {
            return m.results().any(function (value) {
                return !value.IsWarning && value.CorrelationId === correlationId;
            });
        };

        m.hasCorrelatedErrorsOrWarnings = function (correlationId, fieldId) {
            return m.hasGroupedErrors(correlationId, fieldId) || m.hasCorrelatedWarnings(correlationId, fieldId);
        };

        m.hasErrorsOfType = function (fieldId, type) {
            return m.results().any(function (value) {
                return !value.IsWarning && value.FieldId === fieldId && value.Type === type;
            });
        };

        m.messageForField = function (fieldId) {
            return m.readMessage(function (value) {
                return value.FieldId === fieldId;
            });
        };

        m.groupedMessage = function (correlationId, fieldId) {
            return m.readMessage(function (value) {
                return value.FieldId === fieldId && value.CorrelationId === correlationId;
            });
        };

        m.groupHasErrors = function (correlationId) {
            return m.results().any(function (value) {
                return !value.IsWarning && value.CorrelationId === correlationId;
            });
        };

        m.groupHasWarnings = function (correlationId) {
            return m.results().any(function (value) {
                return value.IsWarning && value.CorrelationId === correlationId;
            });
        };

        m.groupHasErrorsOrWarnings = function (correlationId) {
            return m.groupHasWarnings(correlationId) || m.groupHasErrors(correlationId);
        };

        m.correlatedErrorsAndWarnings = function (correlationId) {
            return ko.utils.arrayFilter(m.results(), function (item) {
                return item.CorrelationId === correlationId;
            });
        };

        m.errorsAndWarningsFor = function (fieldId) {
            return ko.utils.arrayFilter(m.results(), function (item) {
                return item.FieldId === fieldId;
            });
        };

        m.nameOrCreditRestrictions = function (fieldId) {
            return ko.utils.arrayFilter(m.results(), function (item) {
                return item.FieldId === fieldId;
            });
        };

        m.readMessage = function (predicate) {
            var r = m.results().firstOrDefault(predicate);

            if (r === null){
                return null;
            }

            if (r.MessageId) {
                return localise.getString(r.MessageId) || r.Message;
            }

            return r.Message;
        };

        m.getErrorsForSpecifiedType = function (fieldId, type) {
            return m.results().where(function (value) {
                return !value.IsWarning && value.FieldId === fieldId && value.Type === type;
            });
        };

        return m;
    };
    return my;
} (batchEventUpdate || {}));
