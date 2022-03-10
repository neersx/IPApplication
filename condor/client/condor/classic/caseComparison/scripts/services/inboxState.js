angular.module('Inprotech.CaseDataComparison')
    .factory('inboxState', function() {
        'use strict';

        var notifications = null;
        var filters = null;
        var selectedIndex = null;
        var dataSources = null;
        var hasMore = false;

        var resetData = function() {
            notifications = null;
            filters = null;
            selectedIndex = null;
            dataSources = null;
        };

        var evaluateNotificationToSelect = function() {
            var notificationsCopy = angular.copy(notifications);

            notificationsCopy.splice(0, selectedIndex);

            notificationsCopy = applyInclusionFiltering(notificationsCopy);

            if (notificationsCopy.length > 0) {
                return _.first(notificationsCopy).notificationId;
            }
        };

        var applyInclusionFiltering = function(items) {
            if (!filters.includeReviewed) {
                items = _.reject(items, { isReviewed: true });
            }

            if (!filters.includeRejected) {
                items = _.reject(items, { type: 'rejected' });
            }

            return items;
        };

        var saveState = function(notificationList, dataSourcesCounts, filterset, selectedNotification, hasMoreNotifications) {
            notifications = notificationList;
            filters = filterset;
            selectedIndex = _.indexOf(notifications, selectedNotification);
            dataSources = dataSourcesCounts;
            hasMore = hasMoreNotifications;
        };

        var pop = function() {
            if (!notifications) {
                return null;
            }

            var selectedNotificationId = evaluateNotificationToSelect();
            notifications = applyInclusionFiltering(notifications);

            var result = {
                notifications: notifications,
                filters: filters,
                notificationIdToSelect: selectedNotificationId || ((notifications.length > 0) ? _.last(notifications).notificationId : null),
                dataSources: dataSources,
                hasMore: hasMore
            };

            resetData();

            return result;
        };

        var updateState = function(updatedNotifications) {
            _.each(updatedNotifications, function(n) {
                var index = _.findIndex(notifications, { notificationId: n.notificationId });
                if (index >= 0) {
                    notifications[index] = n;
                }
            });
        };

        return {
            save: saveState,
            pop: pop,
            updateState: updateState
        };
    });