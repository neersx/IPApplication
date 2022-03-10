angular.module('Inprotech')
    .directive('inDragAndDrop', function() {
        'use strict';
        return {
            restrict: 'A',
            link: function(scope, element, attributes) {

                element.on('drop', function(event) {
                    $(element).removeClass('dragover');
                    event.originalEvent.stopPropagation();
                    event.originalEvent.preventDefault();

                    if (scope.$eval(attributes.ngDisabled) === true) {
                        return;
                    }

                    var files = event.originalEvent.dataTransfer.files;
                    if (files.length === 0) {
                        return;
                    }
                    var eventHandler = scope[attributes.inDragAndDrop];
                    if (eventHandler) {
                        scope.$apply(eventHandler(files));
                    }
                });
                element.on('dragover', function(event) {
                    $(element).addClass('dragover');
                    event.originalEvent.stopPropagation();
                    event.originalEvent.preventDefault();
                });
                element.on('dragenter', function(event) {
                    event.originalEvent.stopPropagation();
                    event.originalEvent.preventDefault();
                });
                element.on('dragleave', function(event) {
                    $(element).removeClass('dragover');
                    event.originalEvent.stopPropagation();
                    event.originalEvent.preventDefault();
                });
            }
        };
    });
