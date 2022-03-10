angular.module('inprotech.dev').controller('TestTopicsController', function () {
    'use strict';

    var vm = this;

    vm.options = {
        topics: [{
            key: 'chars',
            title: 'Characteristics',
            template: '<ip-dev-topics-characteristics data-topic="$topic" data-form="$topic.formData">',
            formData: {
                office: {
                    key: '10273',
                    value: 'Minneapolis'
                }
            }
        }, {
            key: 'events',
            title: 'Event Control',
            template: '<ip-dev-topics-events>'
        }, {
            key: 'entries',
            title: 'Entry Control',
            template: '<ip-dev-topics-events>'
        }],
        actions: [{
            key: 'criteriaNumber',
            title: 'Criteria Number',
            tooltip: 'Criteria Number info tooltip'
        }, {
            key: 'resetCriteria',
            title: 'Reset Criteria'
        }]
    };
});