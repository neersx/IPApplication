angular.module('inprotech.configuration.rules.workflows').factory('workflowsMaintenanceEventsService', function($rootScope, $http, workflowsMaintenanceService, notificationService, modalService) {
    'use strict';

    var _eventIds = [];
    var _newEventIds = [];
    var eventMessagePrefix = 'workflows.maintenance.deleteConfirmationEvent';
    var r = {
        addEventWorkflow: addEventWorkflow,
        showInheritanceConfirmationModal: showInheritanceConfirmationModal,
        getEventFilterMetadata: getEventFilterMetadata,
        getEvents: getEvents,
        searchEvents: searchEvents,
        addEvent: addEvent,
        confirmDeleteWorkflow: confirmDeleteWorkflow,
        checkDescendants: checkDescendants,
        confirmInheritanceDelete: confirmInheritanceDelete,
        confirmDelete: confirmDelete,
        deleteEvents: deleteEvents,
        checkEventsUsedByCases: checkEventsUsedByCases,
        getDescendants: getDescendants,
        getDescendantsWithoutEvent: getDescendantsWithoutEvent,
        reorderEvent: reorderEvent,
        reorderDescendants: reorderDescendants,
        confirmReorderDescendants: confirmReorderDescendants,
        eventIds: eventIds,
        addEventId: addEventId,
        removeEventIds: removeEventIds,
        showCreateEntryModal: showCreateEntryModal,
        refreshEventIds: refreshEventIds,
        isEventNewlyAdded: isEventNewlyAdded,
        resetNewlyAddedEventIds: resetNewlyAddedEventIds
    };

    return r;

    function addEventWorkflow(criteriaId, newEventId, scope) {
        return r.getDescendantsWithoutEvent(criteriaId, newEventId).then(function(descendants) {
            if (descendants && descendants.length > 0) {
                return r.showInheritanceConfirmationModal(criteriaId, newEventId, descendants, scope).then(function(inherit) {
                    return inherit;
                });
            } else {
                return false; // no descendants, don't inherit
            }
        });
    }

    function showInheritanceConfirmationModal(criteriaId, eventId, descendants, scope) {
        var resolve = {
            criteriaId: criteriaId,
            items: descendants,
            context: 'event'
        };
        var dialog = modalService.open('InheritanceConfirmation', scope, {
            viewData: resolve
        });
        return dialog.then(function(applyToDescendants) {
            return applyToDescendants;
        });
    }

    function addEvent(criteriaId, eventId, insertAfterEventId, isInherit) {
        return $http.put('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events/' + encodeURIComponent(eventId) + '?insertAfterEventId=' + encodeURIComponent(insertAfterEventId) + '&applyToChildren=' + encodeURIComponent(isInherit)).then(function(response) {
            notificationService.success();
            return response.data;
        });
    }

    function checkEventsUsedByCases(criteriaId, eventIds) {
        return $http.get('api/configuration/rules/workflows/' + criteriaId + '/events/usedByCases?eventIds=' + JSON.stringify(eventIds))
            .then(function(response) {
                return response.data;
            });
    }

    function getDescendants(criteriaId, eventIds, inheritedOnly) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events/descendants?eventIds=' + JSON.stringify(eventIds) + '&inheritedOnly=' + inheritedOnly)
            .then(function(response) {
                return response.data;
            });
    }

    function getDescendantsWithoutEvent(criteriaId, eventId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/eventdescendants?withoutEventId=' + encodeURIComponent(eventId))
            .then(function(response) {
                return response.data;
            });
    }

    function deleteEvents(criteriaId, eventIds, appliesToDescendants) {
        return $http.delete('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events?eventIds=' + JSON.stringify(eventIds) + '&appliesToDescendants=' + appliesToDescendants);
    }

    function getEventFilterMetadata(criteriaId, field) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events/filterdata/' + encodeURIComponent(field))
            .then(function(response) {
                return response.data;
            });
    }

    function getEvents(criteriaId, queryParams) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events', {
            params: {
                params: JSON.stringify(queryParams)
            }
        })
            .then(function(response) {
                r.eventIds(response.data.ids);
                return response.data;
            });
    }

    function eventIds(eventIds) {
        if (eventIds) {
            _eventIds = eventIds;
        }

        return _eventIds;
    }

    function refreshEventIds(rows) {
        eventIds(pluckEventIds(rows));
    }

    function isEventNewlyAdded(eventNo) {
        return _.contains(_newEventIds, eventNo);
    }

    function resetNewlyAddedEventIds() {
        _newEventIds = [];
    }

    function pluckEventIds(rows) {
        return _.pluck(rows, 'eventNo');
    }

    function removeEventIds(rows) {
        _eventIds = _.difference(_eventIds, pluckEventIds(rows));
    }

    function addEventId(row, insertAfter) {
        var insertIndex;
        if (insertAfter) {
            insertIndex = _eventIds.indexOf(insertAfter.eventNo) + 1;
        } else {
            insertIndex = _eventIds.length
        }
        _eventIds.splice(insertIndex, 0, row.eventNo);
        if (!_.contains(_newEventIds, row.eventNo)) {
            _newEventIds.splice(0, 0, row.eventNo);
        }
    }

    function searchEvents(criteriaId, eventId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/eventSearch?eventId=' + encodeURIComponent(eventId));
    }

    function reorderEvent(criteriaId, sourceId, targetId, insertBefore) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events/reorder', {
            sourceId: sourceId,
            targetId: targetId,
            insertBefore: insertBefore
        }).then(function(response) {
            return response.data;
        });
    }

    function confirmReorderDescendants(criteriaId, sourceId, targetId, prevTargetId, nextTargetId, insertBefore, scope) {
        return r.getDescendants(criteriaId, [sourceId], false).then(function(responseData) {
            var descendants = responseData.descendants;
            if (!descendants || !descendants.length) {
                return null;
            }

            return modalService.open('InheritanceReorderConfirmation', scope, {
                items: function() {
                    return descendants;
                }
            }).then(function() {
                return r.reorderDescendants(criteriaId, sourceId, targetId, prevTargetId, nextTargetId, insertBefore);
            });
        });
    }

    function reorderDescendants(criteriaId, sourceId, targetId, prevTargetId, nextTargetId, insertBefore) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/events/descendants/reorder', {
            sourceId: sourceId,
            targetId: targetId,
            prevTargetId: prevTargetId,
            nextTargetId: nextTargetId,
            insertBefore: insertBefore
        });
    }

    function confirmDeleteWorkflow(scope, criteriaId, selectedEvents) {
        return r.checkEventsUsedByCases(criteriaId, selectedEvents).then(function(usedEvents) {
            if (!usedEvents || !usedEvents.length) {
                return null;
            }

            return modalService.open('EventsForCaseConfirmation', scope, {
                items: function() {
                    return {
                        context: 'event',
                        usedEvents: usedEvents,
                        selectedCount: selectedEvents.length
                    };
                }
            });
        }).then(function() {
            return r.checkDescendants(scope, criteriaId, selectedEvents);
        });
    }

    function checkDescendants(scope, criteriaId, selectedEvents) {
        return r.getDescendants(criteriaId, selectedEvents, true).then(function(responseData) {
            var descendants = responseData.descendants;
            if (descendants && descendants.length) {
                return r.confirmInheritanceDelete(scope, criteriaId, selectedEvents, descendants);
            } else {
                return r.confirmDelete(selectedEvents);
            }
        });
    }

    function confirmInheritanceDelete(scope, criteriaId, selectedEvents, descendants) {
        return modalService.open('InheritanceDeleteConfirmation', scope, {
            items: function() {
                return {
                    context: 'event',
                    descendants: descendants,
                    selectedCount: selectedEvents.length
                };
            }
        }); // returns applyToDescendants
    }

    function confirmDelete(selectedEvents) {
        return notificationService.confirmDelete({
            message: eventMessagePrefix + ((selectedEvents.length > 1) ? '.messageMultiple' : '.messageIndividual'),
            messageParams: {
                count: selectedEvents.length
            }
        });
    }

    function showCreateEntryModal(scope, criteriaId, selectedEvents) {
        var viewData = {
            criteriaId: criteriaId,
            selectedEvents: selectedEvents
        }
        return modalService.open('CreateEntries', scope, {
            viewData: viewData
        });
    }
});