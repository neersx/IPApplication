angular.module('Inprotech.Integration.PtoAccess')
    .controller('scheduleController', ScheduleController);

function ScheduleController(viewInitialiser) {
    'use strict';

    var vm = this;
    vm.$onInit = onInit;

    function onInit() {

        vm.viewData = viewInitialiser.viewData;

        vm.topicOptions = {
            topics: [{
                key: 'definition',
                title: 'dataDownload.schedule.definition',
                template: '<ip-schedule-definition-topic data-topic="$topic">',
                params: {
                    viewData: vm.viewData
                }
            }],
            actions: []
        };

        vm.topicOptions.topics.push({
            key: 'recent-history',
            title: 'dataDownload.schedule.recentHistoryTitle',
            template: '<ip-schedule-recent-history-topic data-topic="$topic" />',
            params: {
                viewData: vm.viewData
            }
        });
    }
}