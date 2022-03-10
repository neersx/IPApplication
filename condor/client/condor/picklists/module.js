angular.module('inprotech.picklists', [
    'inprotech.api.extensions',
    'inprotech.components'
]);

angular.module('inprotech.picklists')
    .run(function(modalService) {
        'use strict';

        modalService.register('ConfirmPropagateEventChanges', 'ConfirmPropagateEventChangesController', 'condor/picklists/events/confirm-propagatechanges.html', {
            windowClass: 'centered',
            size: 'lg',
            controllerAs: 'vm'
        });
    });
