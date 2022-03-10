angular.module('Inprotech')
.directive('inInputFile', function() {
    'use strict';
    return {
        restrict: 'A',
        scope: {
            selected: '&',
            ngDisabled: '='
        },

        link: function(scope, element, attributes) {

            function createInputElement() {
                var f = $('<input type="file" class="internal-file-input" accept="' + attributes.accept + '" />');

                $(element).append(f);

                f.on('change', onChange);

                return f[0];
            }

            function onChange() {

                if (scope.ngDisabled === true) {
                    return;
                }

                var files = inputElement.files;
                if (files.length === 0) {
                    return;
                }

                var handler = scope.selected();
                if (handler) {
                     scope.$apply(handler(files));
                }

                cleanUp();

                inputElement = createInputElement();
            }

            function cleanUp() {
                $(inputElement).unbind();
                $(inputElement).remove();

                inputElement = null;
            }

            var inputElement = createInputElement();

            scope.$on('$destroy', function() {
                cleanUp();
            });
        }
    };
});
