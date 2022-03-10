'use strict';

describe('notificationService', function() {
    var _inboxState;

    beforeEach(module('Inprotech.CaseDataComparison'));

    beforeEach(inject(function(inboxState) {
        _inboxState = inboxState;
    }));

    var selectedNotification = { notificationId: 99, isReviewed: false };
    var stateToSave = {
        notifications: [{ notificationId: 1 }, selectedNotification, { notificationId: 100 }],
        dataSources: [{ someSources: 10 }],
        filters: { includeReviewed: false, includeRejected: false },
        hasMore: true,
        selectedNotification: selectedNotification
    };

    var init = function(state) {
        _inboxState.save(state.notifications, state.dataSources, state.filters, state.selectedNotification, state.hasMore);
    };

    it('should save the provided details and return on pop', function() {
        init(stateToSave);

        var result = _inboxState.pop();
        expect(result).not.toBe(null);

        expect(result.notifications).toEqual(stateToSave.notifications);
        expect(result.filters).toEqual(stateToSave.filters);
        expect(result.notificationIdToSelect).toBe(99);
        expect(result.dataSources).toEqual(stateToSave.dataSources);
        expect(result.hasMore).toBe(stateToSave.hasMore);
    });

    it('should apply updates on saved state and return while pop', function() {
        init(stateToSave);

        _inboxState.updateState([{ notificationId: 1, isReviewed: true }]);

        var result = _inboxState.pop();

        var notification1 = _.findWhere(result.notifications, { notificationId: 1 });
        expect(notification1).toBe(undefined);

        expect(result.notifications.length).toBe(2);
        expect(result.notificationIdToSelect).toBe(99);
    });

    it('should evaluate the new next notification by reapplying filtering', function() {
        init(stateToSave);

        _inboxState.updateState([{ notificationId: 99, isReviewed: true }]);

        var result = _inboxState.pop();

        expect(result.notificationIdToSelect).toBe(100);
    });
});