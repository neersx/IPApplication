angular.module('inprotech.components.buttons')
    .directive('ipSaveButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            templateUrl: 'condor/components/buttons/saveButton.html'
        };
    })
    .directive('ipCloseButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            templateUrl: 'condor/components/buttons/closeButton.html'
        };
    })
    .directive('ipRevertButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            templateUrl: 'condor/components/buttons/revertButton.html'
        };
    })
    .directive('ipIconButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            template: function(iElement, iAttrs) {
                return '<button class="btn btn-icon"><icon name="' + iAttrs.buttonIcon + '"></icon></button>';
            }
        };
    })
    .directive('ipAddButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            templateUrl: 'condor/components/buttons/addButton.html'
        };
    })
    .directive('ipStepButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: {
                stepNo: '='
            },
            replace: true,
            templateUrl: 'condor/components/buttons/stepButton.html'
        };
    })
    .directive('ipApplyButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            templateUrl: 'condor/components/buttons/applyButton.html'
        };
    })
    .directive('ipAdvancedSearchButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            templateUrl: 'condor/components/buttons/advancedSearchButton.html'
        };
    })
    .directive('ipClearButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: false,
            replace: true,
            templateUrl: 'condor/components/buttons/clearButton.html'
        };
    })
    .directive('ipPreviewButton', function() {
        'use strict';

        return {
            restrict: 'E',
            scope: {
                isPreviewActive: '='
            },
            replace: true,
            templateUrl: 'condor/components/buttons/previewButton.html'
        };
    });