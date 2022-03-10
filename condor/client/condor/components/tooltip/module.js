(function() {
    'use strict';
    angular.module('inprotech.components.tooltip', [
        'ui.bootstrap'
    ]);

    angular.module('inprotech.components.tooltip').config(function($uibTooltipProvider) {
        $uibTooltipProvider.options({
            placement: 'top auto',
            appendToBody: true,
            trigger: 'mouseenter'
        });
    });
})();
