angular.module('inprotech.configuration.general.events.eventnotetypes', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]);

angular.module('inprotech.configuration.general.events.eventnotetypes')
    .run(function (modalService) {
        modalService.register('EventNoteTypesMaintenance', 'EventNoteTypesMaintenanceController', 'condor/configuration/general/events/eventnotetypes/eventnotetypes.maintenance.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });

angular.module('inprotech.configuration.general.events.eventnotetypes').config(($stateProvider) => {
    $stateProvider.state('eventnotetypes', {
        url: '/configuration/general/events/eventnotetypes',
        templateUrl: 'condor/configuration/general/events/eventnotetypes/eventnotetypes.html',
        controller: 'EventNoteTypesController',
        controllerAs: 'vm',
        resolve: {
            viewData: (EventNoteTypesService) => {
                return EventNoteTypesService.viewData();
            }
        },
        data: {
            pageTitle: 'Event Note Type Maintenance'
        }
    });
});