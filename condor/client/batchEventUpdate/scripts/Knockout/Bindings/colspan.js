ko.bindingHandlers.colspan = {
    init: function (element, valueAccessor) {
        'use strict';
        var v = valueAccessor();
        
        if(!v) {
            return;
        }

        var colspan = (v.IsCyclic() === true ? 1 : 0) +
                    (v.EventDateEntryAttribute.IsVisible() ? 1 : 0) +
                    (v.DueDateEntryAttribute.IsVisible() ? 1 : 0) + 
                    1; // Add this one for eventtext.
        
        $(element).attr('colspan', colspan);
    }
};