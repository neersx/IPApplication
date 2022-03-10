var batchEventUpdate = (function (my) {
    'use strict';
    
    my.nonUpdatableCaseViewModel = function(model) {
        var m =  ko.mapping.fromJS(model);

        var filterByRestrictionSeverity = function(severity) {
            return m.CaseNameRestrictions().where(function(cnr) {
                return cnr.Restrictions().any(function(r) {
                     return r.Severity() === severity;
                });
            });
        };

        m.blockingNameRestrictions = function() {
            return filterByRestrictionSeverity('Error');
        };

        m.nameRestrictionsRequiringPasswordApproval = function() {
            return filterByRestrictionSeverity('Warning');
        };

        return m;
    };
    return my;
}(batchEventUpdate || {}));