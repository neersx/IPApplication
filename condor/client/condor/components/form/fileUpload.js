angular.module('inprotech.components.form')
    .directive('ipUploadFile', function() {
        'use strict';
        return {
            restrict: 'A',
            scope: {
                fileSelected: '&'
            },
            require: {
                'ngModel': '?ngModel',
                'formCtrl': '?^ipForm'
            },
            controllerAs: 'vm',
            controller: function($element, $attrs, formControlHelper, $scope) {
                'use strict';
                var vm = this;
                vm.id = $scope.$id;
                vm.formControlHelper = formControlHelper;
            },
            link: function(scope, element, attrs, controllers) {
                var vm = scope.vm;
                vm.$onInit = onInit;
                element.on('change', onChange);

                function onChange() {
                    var input = $(this)[0];
                    if (scope.ngDisabled === true) {
                        return;
                    }

                    var files = input.files;
                    if (files.length === 0) {
                        scope.$apply(controllers.ngModel.$setViewValue(''));
                        return;
                    }
                    scope.$apply(controllers.ngModel.$setViewValue(files[0].name));
                    var handler = scope.fileSelected();
                    if (handler) {
                        scope.$apply(handler(files));
                    }
                }

                function onInit() {
                    vm.formControlHelper.init({
                        scope: vm,
                        element: element,
                        attrs: attrs,
                        ngModelCtrl: controllers.ngModel,
                        formCtrl: controllers.formCtrl
                    });
                }
                onInit();
            }
        };
    });