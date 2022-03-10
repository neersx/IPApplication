angular.module('inprotech.components.form').directive('ipCopyText', function (clipboard, $compile, scheduler, $timeout) {
    'use strict';

    return {
        restrict: 'A',
        scope: {},
        link: function (scope: any, element, attributes) {
            if (!clipboard.supported) {
                return;
            }

            let text = attributes.ipCopyText;
            if (!text) {
                let tagName = element.prop('tagName').toLowerCase();
                if (_.contains(['span', 'div', 'label'], tagName)) {
                    $timeout(() => {
                        text = element.text();
                    });
                }
            }

            function createCopyElement() {
                let f = $('<span style="cursor:pointer;padding-left: 10px;" class="cpa-icon cpa-icon-file-stack-o" name="file-stack-o" ip-tooltip="{{ copyStatus | translate }}"></span>');
                f.on('click', onClick);
                $(element).append(f);

                $compile(f)(scope);
                return f[0];
            }

            function onClick() {
                clipboard.copyText(text);
                scope.copyStatus = 'copied';

                scheduler.runOutsideZone(() => {
                    $timeout(() => {
                        scope.copyStatus = 'copy';
                    }, 5000);
                });
            }

            scope.copyStatus = 'copy';
            let inputElement = createCopyElement();

            function cleanUp() {
                $(inputElement).unbind();
                $(inputElement).remove();
                inputElement = null;
            }

            scope.$on('$destroy', function () {
                if (inputElement) {
                    cleanUp();
                }
            });
        }
    };
});