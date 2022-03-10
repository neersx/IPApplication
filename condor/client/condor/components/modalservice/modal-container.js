angular.module('inprotech.components.modal')
    .controller('ModalContainerController', function($scope, $compile, $templateRequest, $uibModalInstance, $controller, options) {
        'use strict';

        var destroyCurrentView = angular.noop;

        $scope.$on('modalChangeView', function(evt, newOptions) {
            destroyCurrentView();
            load(newOptions);
        });

        load();

        function load(overwrites) {
            var newOptions = angular.extend({}, options, overwrites);

            $templateRequest(newOptions.templateUrl).then(function(content) {
                var newScope = $scope.$new();
                var el = angular.element(content);
                var ctrlInstance = $controller(newOptions.controller, {
                    $scope: newScope,
                    $uibModalInstance: $uibModalInstance,
                    $element: el,
                    options: newOptions
                });

                $uibModalInstance.rendered.then(function() {
                    if (options.controllerAs) {
                        newScope[options.controllerAs] = ctrlInstance;
                    }

                    $('#' + newOptions.id + ' .modal-content:last').append(el);
                    $compile(el)(newScope);
                });

                destroyCurrentView = function() {
                    newScope.$destroy();
                    el.remove();
                };
            });
        }
    });
