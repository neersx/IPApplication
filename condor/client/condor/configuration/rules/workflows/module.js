angular.module('inprotech.configuration.rules.workflows', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components',
    'inprotech.configuration.general.validcombination',
    'inprotech.portfolio.cases'
]);

angular.module('inprotech.configuration.rules.workflows')
    .run(function(modalService) {
        'use strict';

        modalService.register('InheritanceConfirmation', 'InheritanceConfirmationController', 'condor/configuration/rules/workflows/maintenance/inheritance-confirmation.html', {
            windowClass: 'centered picklist-window',
            controllerAs: 'vm',
            size: 'lg'
        });

        modalService.register('EventInheritanceConfirmation', 'EventInheritanceConfirmationController', 'condor/configuration/rules/workflows/eventcontrol/inheritance-confirmation.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm'
        });

        modalService.register('EntryInheritanceConfirmation', 'EntryInheritanceConfirmationController', 'condor/configuration/rules/workflows/entrycontrol/inheritance-confirmation.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm'
        });

        modalService.register('ChangeDueDateRespConfirm', 'ChangeDueDateRespConfirmController', 'condor/configuration/rules/workflows/eventcontrol/change-due-date-resp-confirm.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            controllerAs: 'vm'
        });

        modalService.register('InheritanceReorderConfirmation', 'InheritanceReorderConfirmationController', 'condor/configuration/rules/workflows/maintenance/inheritance-reorder-confirmation.html', {
            windowClass: 'centered picklist-window',
            controllerAs: 'vm'
        });

        modalService.register('InheritanceDeleteConfirmation', 'InheritanceDeleteConfirmationController', 'condor/configuration/rules/workflows/maintenance/inheritance-delete-confirmation.html', {
            windowClass: 'centered picklist-window',
            controllerAs: 'vm',
            size: 'lg'
        });

        modalService.register('EntryInheritanceDeleteConfirmation', 'EntryInheritanceDeleteConfirmationController', 'condor/configuration/rules/workflows/entrycontrol/inheritance-delete-confirmation.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm'
        });

        modalService.register('InheritanceResetConfirmation', 'InheritanceResetConfirmationController', 'condor/configuration/rules/workflows/entrycontrol/inheritance-reset-confirmation.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm',
            size: 'lg'
        });

        modalService.register('InheritanceBreakConfirmation', 'InheritanceBreakConfirmationController', 'condor/configuration/rules/workflows/entrycontrol/inheritance-break-confirmation.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm'
        });

        modalService.register('EventsForCaseConfirmation', 'EventsForCaseConfirmationController', 'condor/configuration/rules/workflows/maintenance/events-for-case-confirmation.html', {
            windowClass: 'centered picklist-window',
            backdrop: 'static',
            controllerAs: 'vm'
        });

        modalService.register('InheritanceChangeConfirmation', 'InheritanceChangeConfirmationController', 'condor/configuration/rules/workflows/inheritance/inheritance-change-confirmation.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            controllerAs: 'vm'
        });

        modalService.register('CriteriaUnableToDelete', 'NotificationController', 'condor/configuration/rules/workflows/inheritance/criteria-unable-to-delete.html', {
            windowClass: 'centered picklist-window modal-alert',
            controllerAs: 'vm'
        });

        modalService.register('CreateCharacteristics', 'CreateCharacteristicsController', 'condor/configuration/rules/workflows/maintenance/create-characteristics.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            controllerAs: 'vm'
        });

        modalService.register('DueDateCalcMaintenance', 'DueDateCalcMaintenanceController', 'condor/configuration/rules/workflows/eventcontrol/due-date-calc-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            bindToController: true,
            controllerAs: 'vm'
        });

        modalService.register('DateComparisonMaintenance', 'DateComparisonMaintenanceController', 'condor/configuration/rules/workflows/eventcontrol/date-comparison-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            bindToController: true,
            controllerAs: 'vm'
        });

        modalService.register('CreateEntries', 'CreateEntriesController', 'condor/configuration/rules/workflows/maintenance/create-entries.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            controllerAs: 'vm'
        });

        modalService.register('EntryEventMaintenance', 'EntryEventMaintenanceController', 'condor/configuration/rules/workflows/entrycontrol/entry-event-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            bindToController: true,
            controllerAs: 'vm'
        });

        modalService.register('EntryStepsMaintenance', 'EntryStepsMaintenanceController', 'condor/configuration/rules/workflows/entrycontrol/steps-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            bindToController: true,
            controllerAs: 'vm'
        });

        modalService.register('RemindersMaintenance', 'RemindersMaintenanceController', 'condor/configuration/rules/workflows/eventcontrol/reminders-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            bindToController: true,
            controllerAs: 'vm'
        });

        modalService.register('DateLogicMaintenance', 'DateLogicMaintenanceController', 'condor/configuration/rules/workflows/eventcontrol/date-logic-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            bindToController: true,
            controllerAs: 'vm'
        });

        modalService.register('DocumentsMaintenance', 'DocumentsMaintenanceController', 'condor/configuration/rules/workflows/eventcontrol/documents-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            bindToController: true,
            controllerAs: 'vm'
        });

        modalService.register('OverviewMaintenance', 'OverviewMaintenanceController', 'condor/configuration/rules/workflows/eventcontrol/overview-maintenance.html', {
            windowClass: 'centered picklist-window',
            size: 'lg',
            controllerAs: 'vm'
        });
    });

angular.module('inprotech.configuration.rules.workflows').config(function($stateProvider, typeaheadConfigProvider) {
    'use strict';

    $stateProvider.state('workflows', {
        url: '/configuration/rules/workflows',
        templateUrl: 'condor/configuration/rules/workflows/search/search.html',
        controller: 'WorkflowsSearchController',
        controllerAs: 'vm',
        resolve: {
            viewData: function($http) {
                return $http.get('api/configuration/rules/workflows/view').then(function(response) {
                    return response.data;
                });
            }
        },
        data: {
            pageTitle: 'workflows.title'
        },
        onRetain: ['caseValidCombinationService', function(caseValidCombinationService) {
            caseValidCombinationService.resetFormData();
        }]
    })
        .state('workflows.inheritance', {
            url: '/inheritance?criteriaIds&selectedNode',
            params: {
                selectedNode: {
                    dynamic: true
                }
            },
            templateUrl: 'condor/configuration/rules/workflows/inheritance/inheritance.html',
            controller: 'WorkflowsInheritanceController',
            controllerAs: 'vm',
            resolve: {
                viewData: function($http, $stateParams) {
                    var uri = 'api/configuration/rules/workflows/inheritance?criteriaIds=' + encodeURI($stateParams.criteriaIds);
                    if ($stateParams.selectedNode) {
                        uri += '&selectedNode=' + encodeURI($stateParams.selectedNode);
                    }
                    return $http.get(uri).then(function(response) {
                        return response.data;
                    });
                }
            }
        })
        .state('workflows.details', {
            url: '/{id}',
            templateUrl: 'condor/configuration/rules/workflows/maintenance/maintenance.html',
            controller: 'WorkflowsMaintenanceController',
            controllerAs: 'vm',
            resolve: {
                viewData: function($http, $stateParams) {
                    return $http.get('api/configuration/rules/workflows/' + $stateParams.id).then(function(response) {
                        return response.data;
                    });
                }
            }
        })
        .state('workflows.details.eventcontrol', {
            url: '/eventcontrol/{eventId}',
            templateUrl: 'condor/configuration/rules/workflows/eventcontrol/event-control.html',
            controller: 'WorkflowsEventControlController',
            controllerAs: 'vm',
            resolve: {
                viewData: function($http, $stateParams) {
                    return $http.get('api/configuration/rules/workflows/' + $stateParams.id + '/eventcontrol/' + $stateParams.eventId).then(function(response) {
                        return response.data;
                    })
                }
            }
        })
        .state('workflows.details.entrycontrol', {
            url: '/entrycontrol/{entryId}',
            templateUrl: 'condor/configuration/rules/workflows/entrycontrol/entry-control.html',
            controller: 'WorkflowsEntryControlController',
            controllerAs: 'vm',
            resolve: {
                viewData: function($http, $stateParams) {
                    return $http.get('api/configuration/rules/workflows/' + $stateParams.id + '/entrycontrol/' + $stateParams.entryId).then(function(response) {
                        if (response.data.description === '') {
                            response.data.description = ' ';
                        }
                        return response.data;
                    })
                }
            }
        });

    typeaheadConfigProvider.config('eventsFilteredByCriteria', {
        label: 'picklist.event.Type',
        keyField: 'key',
        codeField: 'key',
        textField: 'value',
        restmodApi: 'events',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/directives/criteria-event-picklist-template.html',
        picklistDisplayName: 'picklist.event.Type',
        size: 'xl',
        columnMenu: true,
        displayCodeWithText: true,
        initFunction: function(vm) {
            if (!vm.searchValue && _.isEmpty(vm.searchValue)) {
                vm.externalScope.filterByCriteria = true;
            }
            var originalCriteriaId = vm.externalScope.criteriaId;
            _.extend(vm.externalScope, {
                originalCriteriaId: originalCriteriaId,
                picklistSearch: true
            });
        },
        preSearch: function(vm) {
            var originalCriteriaId = vm.externalScope.originalCriteriaId;
            _.extend(vm.externalScope, {
                criteriaId: vm.externalScope.filterByCriteria ? originalCriteriaId : null,
                picklistSearch: true
            });
        }
    });

    typeaheadConfigProvider.config('statusFiltered', {
        label: 'picklist.status.label',
        keyField: 'key',
        codeField: 'code',
        textField: 'value',
        apiUrl: 'api/picklists/status',
        itemTemplateUrl: 'condor/components/form/autocomplete-item-code-desc.html',
        picklistTemplateUrl: 'condor/configuration/rules/workflows/search/valid-picklist-filtered-template.html',
        picklistColumns: "[{title:'picklist.status.Description', field:'value', width: '50%'}, {title:'picklist.status.Code', field:'code', width:'20%'},{title:'picklist.status.Type', field:'type', width:'30%'}]",
        picklistDisplayName: 'picklist.status.label',
        initFunction: function(vm) {
            if (vm.externalScope.canAddValidCombinations) {
                vm.externalScope.filterByCriteria = !vm.searchValue && _.isEmpty(vm.searchValue);
            }
        },
        preSearch: function(vm) {
            if (vm.externalScope.canAddValidCombinations) {
                vm.externalScope.filterByCriteria = !vm.searchValue && _.isEmpty(vm.searchValue);
            }
        }
    });
});