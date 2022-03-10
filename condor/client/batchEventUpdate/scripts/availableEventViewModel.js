var batchEventUpdate = (function(my) {
    'use strict';

    my.availableEventViewModel = function(availableEvent) {

        var m = ko.mapping.fromJS(availableEvent);

        m.eventDate = utilities.observableDate(m.EventDate, function(date) {
            m.IsStopPolicing(date !== null);
        });

        m.dueDate = utilities.observableDate(m.DueDate);
        m.defaultDatesAreSet = false;

        var today = (new Date()).toDateString();

        if (availableEvent.EventDateEntryAttribute.ShouldDefaultToSystemDate && !availableEvent.EventDate) {
            m.eventDate(today);
            m.defaultDatesAreSet = true;
        }

        if (availableEvent.DueDateEntryAttribute.ShouldDefaultToSystemDate && !availableEvent.DueDate) {
            m.dueDate(today);
            m.defaultDatesAreSet = true;
        }

        return m;
    };

    my.availableEvent = function(availableEvent) {
        availableEvent.EventDate = utilities.toISODateString(availableEvent.EventDate);
        availableEvent.DueDate = utilities.toISODateString(availableEvent.DueDate);

        return availableEvent;
    };

    return my;
}(batchEventUpdate || {}));