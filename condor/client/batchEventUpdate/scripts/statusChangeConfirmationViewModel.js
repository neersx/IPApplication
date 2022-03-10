var batchEventUpdate = (function(my) {
    'use strict';
    
    my.statusChangeConfirmationViewModel = function(cases, criteriaId, dataEntryTaskId, newStatus, requiresPassword, then) {
        var _element;

        var m = application.modalDialogViewModel();

        m = $.extend(m, {
            requiresPassword: ko.observable(requiresPassword),
            password: ko.observable(),
            newStatus: ko.observable(newStatus),
            isInvalidPassword: ko.observable(false),
            cases: ko.observable(cases)
        });

        m.statusChangingCases = ko.computed(function() {
            return m.cases().where(function(c) {
                return c.CaseStatusDescription() !== newStatus;
            });
        });

        m.onConfirm = function() {
            batchEventUpdate.saveCommand({
                modifiedCases: m.cases(),
                criteriaId: criteriaId,
                dataEntryTaskId: dataEntryTaskId,
                passwordForStatusChange: m.password(),
                then: function(result) {

                    var filterResult = function(invalidPasswordErrors) {
                        return result.where(function(r) {
                            return r.ValidationResults.any(function(vr) {
                                return vr.Details.Name === 'InvalidPasswordForStatusChange';
                            }) === invalidPasswordErrors;
                        });
                    };

                    m.isInvalidPassword(filterResult(true).any());

                    var otherResults = filterResult(false);

                    var invokeThen = function(completed, r) {
                        then({ isCompleted: completed, result: r });
                    };

                    if (!m.isInvalidPassword()) {
                        m.close();
                        invokeThen(true, result);                         
                    } else {
                        invokeThen(false, otherResults);
                        m.cases(m.statusChangingCases());
                    }
                }
            });
        };

        return m;
    };
    return my;
}(batchEventUpdate || {}));
