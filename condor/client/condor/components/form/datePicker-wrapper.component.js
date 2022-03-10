angular.module('inprotech.components.form')
    .component('ipDatePickerWrapper', {
        controllerAs: 'vm',       
        bindings: {
            class: '@,',
            label: '@?',
            isDisabled: '=?',
            readonly: '=?',
            onblur: '&?',
            onBlurNg: '&?',
            ngModel: '=',
            earlierThan: '=?',
            laterThan: '=?',
            includeSameDate: '@?',
            isSaved: '=?',
            inlineDataItemId: '@?',
            noEditState: '=?',
            isRequired: '@?',
            useLocalTimezone: '<'
        },
        template: '<ip-datepicker class="vm.class" ng-model="vm.ngModel" label="{{vm.label}}" ' +
            'is-disabled="vm.isDisabled" readonly="vm.readonly" on-blur-ng="vm.onblur" ' +
            'earlier-than="vm.earlierThan" later-than="vm.laterThan" include-same-date="{{vm.includeSameDate}}"' +
            'is-saved="vm.isSaved" inline-data-item-id="{{vm.inlineDataItemId}}"' +
            'no-edit-state="vm.noEditState" ng-required="vm.isRequired" use-local-timezone="vm.useLocalTimezone"></ip-datepicker>',            
        controller: function () {}
    });