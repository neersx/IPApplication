angular.module('inprotech.components.form').component('ipTextField', {
    templateUrl: ['$attrs', function ($attrs) {
        if ($attrs.ipSqlHighlight != null) {
            return 'condor/components/form/sqlTextArea.html';
        }
        if ($attrs.multiline != null) {
            return 'condor/components/form/textArea.html';
        }
        return 'condor/components/form/textField.html';
    }],
    bindings: {
        label: '@',
        maxLength: '=ngMaxlength',
        rows: '@?', // textArea only,
        trim: '@ngTrim',
        warningText: '&',
        mask: '<?',
        placeholder: '@',
        errorParam: '@',
        ngBlur: '&?'
    },
    require: {
        'ngModel': '?ngModel',
        'formCtrl': '?^ipForm'
    },
    controllerAs: 'vm',
    controller: function ($element, $attrs, formControlHelper, $scope) {
        'use strict';

        var vm = this;

        vm.$onInit = onInit;

        vm.codeMirrorOptions = {
            theme: 'ssms',
            mode: 'text/x-sqlite',
            readOnly: ($attrs.disabled != null ? "nocursor" : false),
            lineWrapping: true,
            lineNumbers: true,
            viewportMargin: Infinity,
            lineSeparator: '\r\n'
        };

        $element.on('setFocus', function () {
            var input = $element.find('input, textArea');
            if (input) {
                input.focus();
            }
        });

        function onInit() {
            vm.id = $scope.$id;
            vm.sqlHighlight = $attrs.ipSqlHighlight != null;
            if (!vm.mask) {
                vm.mask = false;
            }
            formControlHelper.init({
                scope: vm,
                className: 'ip-textfield',
                element: $element,
                attrs: $attrs,
                ngModelCtrl: vm.ngModel,
                formCtrl: vm.formCtrl
            });
        }
    }
});