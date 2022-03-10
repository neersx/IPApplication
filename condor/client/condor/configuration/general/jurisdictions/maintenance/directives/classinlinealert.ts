angular.module('inprotech.configuration.general.jurisdictions').directive('classInlineAlert', () => {
    'use strict';

    return {
        restrict: 'EA',
        controllerAs: 'vm',
        template: '<div class="alert alert-info"><icon name="info-circle"></icon> <a ui-sref="jurisdictions.default({id: ZZZ, navigatedSource: classes})" target="_blank" id="classJurisdiction" translate="jurisdictions.maintenance.classes.clickHere"></a> <span>{{"jurisdictions.maintenance.classes.inlineInfoMessage" | translate}}</span></div>'
    };
});