angular.module('inprotech.components.notification', [])
    .run(function(modalService) {
        modalService.register('ieRequired', 'IeRequiredController', 'condor/components/notification/ieRequired.html', {
            windowClass: 'centered',
            backdropClass: 'centered',
            size: 'lg'
        });
    });