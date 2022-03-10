angular.module('inprotech.configuration.rules.workflows').factory('workflowsMaintenanceEntriesService', function($http, modalService, notificationService) {
    'use strict';

    var _entryIds = [];
    var entryMessagePrefix = 'workflows.maintenance.deleteConfirmationEntry';
    var service = {
        getEntries: getEntries,
        searchEntryEvents: searchEntryEvents,
        entryIds: entryIds,
        reorderEntry: reorderEntry,
        reorderDescendantsEntry: reorderDescendantsEntry,
        showCreateEntryModal: showCreateEntryModal,
        addEntry: addEntry,
        addEntryEvents: addEntryEvents,
        addEntryWorkflow: addEntryWorkflow,
        getDescendantsWithoutEntry: getDescendantsWithoutEntry,
        getDescendantsWithInheritedEntry: getDescendantsWithInheritedEntry,
        showInheritanceConfirmationModal: showInheritanceConfirmationModal,
        confirmDeleteWorkflow: confirmDeleteWorkflow,
        deleteEntries: deleteEntries
    };

    return service;

    function getEntries(criteriaId, queryParams) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entries', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            })
            .then(function(response) {
                return response.data;
            });
    }

    function searchEntryEvents(criteriaId, eventId) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entryEventSearch?eventId=' + encodeURIComponent(eventId));
    }

    function entryIds(rows) {
        if (rows) {
            _entryIds = _.pluck(rows, 'entryNo');
        }

        return _entryIds;
    }

    function reorderEntry(criteriaId, sourceId, targetId, insertBefore) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entries/reorder', {
            sourceId: sourceId,
            targetId: targetId,
            insertBefore: insertBefore
        }).then(function(response) {
            return response.data;
        });
    }

    function reorderDescendantsEntry(criteriaId, sourceId, targetId, prevTargetId, nextTargetId, insertBefore) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entries/descendants/reorder', {
            sourceId: sourceId,
            targetId: targetId,
            prevTargetId: prevTargetId,
            nextTargetId: nextTargetId,
            insertBefore: insertBefore
        });
    }

    function showCreateEntryModal(scope, criteriaId, insertAfterEntryId) {
        var viewData = {
            criteriaId: criteriaId,
            insertAfterEntryId: insertAfterEntryId
        }
        return modalService.open('CreateEntries', scope, {
            viewData: viewData
        });
    }

    function addEntryWorkflow(criteriaId, entryDescription, isSeparator, scope) {
        return service.getDescendantsWithoutEntry(criteriaId, entryDescription, isSeparator).then(function(descendants) {
            if (descendants.length > 0) {
                return service.showInheritanceConfirmationModal(criteriaId, descendants, scope).then(function(inherit) {
                    return inherit;
                });
            } else {
                return false; // no descendants, don't inherit
            }
        });
    }

    function addEntry(criteriaId, entryDescription, isSeparator, insertAfterEntryId, isInherit) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entries', {
            entryDescription: entryDescription,
            isSeparator: isSeparator,
            insertAfterEntryId: insertAfterEntryId,
            applyToChildren: isInherit
        });
    }

    function addEntryEvents(criteriaId, entryDescription, selectedEvents, isInherit) {
        return $http.post('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/eventsentry?entryDescription=' + encodeURIComponent(entryDescription) + '&applyToChildren=' + encodeURIComponent(isInherit), selectedEvents);
    }

    function getDescendantsWithoutEntry(criteriaId, entryDescription, isSeparator) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entrydescendants?withoutEntryDescription=' + encodeURIComponent(entryDescription) + '&isSeparator=' + isSeparator)
            .then(function(response) {
                return response.data;
            });
    }

    function getDescendantsWithInheritedEntry(criteriaId, entryIds) {
        return $http.get('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entries/descendants?withInheritedEntryIds=' + JSON.stringify(entryIds))
            .then(function(response) {
                return response.data;
            });
    }

    function showInheritanceConfirmationModal(criteriaId, descendants, scope) {
        var resolve = {
            criteriaId: criteriaId,
            items: descendants,
            context: 'entry'
        };
        var dialog = modalService.open('InheritanceConfirmation', scope, {
            viewData: resolve
        });
        return dialog.then(function(applyToDescendants) {
            return applyToDescendants;
        });
    }

    function confirmDeleteWorkflow(scope, criteriaId, selectedEntries) {
        return service.getDescendantsWithInheritedEntry(criteriaId, selectedEntries).then(function(descendants) {
            if (descendants && descendants.length) {
                return confirmInheritanceDelete(scope, criteriaId, selectedEntries, descendants);
            } else {
                return confirmDelete(selectedEntries);
            }
        });
    }

    function confirmInheritanceDelete(scope, criteriaId, selectedEntries, descendants) {
        return modalService.open('InheritanceDeleteConfirmation', scope, {
            items: function() {
                return {
                    context: 'entry',
                    descendants: descendants,
                    selectedCount: selectedEntries.length
                };
            }
        }); // returns applyToDescendants
    }

    function confirmDelete(selectedEntries) {
        return notificationService.confirmDelete({
            message: entryMessagePrefix + ((selectedEntries.length > 1)?'.messageMultiple': '.messageIndividual'),
            messageParams: {
                count: selectedEntries.length
            }
        });
    }

    function deleteEntries(criteriaId, entryIds, appliesToDescendants) {
        return $http.delete('api/configuration/rules/workflows/' + encodeURIComponent(criteriaId) + '/entries?entryIds=' + JSON.stringify(entryIds) + '&appliesToDescendants=' + appliesToDescendants);
    }
});
