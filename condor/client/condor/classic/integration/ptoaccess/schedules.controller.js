angular.module('Inprotech.Integration.PtoAccess')
    .controller('schedulesController', SchedulesController);

function SchedulesController($scope, $http, $location, $rootScope, $translate, knownValues, url, dataSourceMap, modalService, kendoGridBuilder, notificationService) {
    'use strict';

    var vm = this;

    vm.$onInit = onInit;

    function onInit() {
        vm.onAdd = onAdd;
        vm.onDelete = onDelete;
        vm.onRunNow = onRunNow;
        vm.onStop = onStop;
        vm.onPause = onPause;
        vm.onResume = onResume;
        vm.gridOptions = buildGridOptions();

        vm.ScheduleStateEnum = {
            Active: 0,
            Expired: 1,
            Purgatory: 2
        };
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            scrollable: false,
            reorderable: false,
            navigatable: true,
            serverFiltering: false,
            autoBind: true,
            read: function () {
                return $http.get(url.api('ptoaccess/schedulesview'))
                    .then(function (response) {
                        return setSchedulesData(response.data.schedules);
                    });
            },
            columns: [{
                title: 'dataDownload.schedules.nextRun',
                width: '100px',
                fixed: true,
                template: function (dataItem) {
                    if (dataItem.type !== knownValues.scheduleType.continuous) {
                        return '<ip-date model="dataItem.nextRun"></ip-date>{{dataItem.statusDesc}}</span>';
                    }
                    return '';
                }
            }, {
                title: 'dataDownload.schedules.description',
                sortable: true,
                template: '<schedule-description model="dataItem"><schedule-description>'
            }, {
                title: 'dataDownload.schedules.dataSource',
                field: 'dataSourceName',
                sortable: true
            }, {
                title: 'dataDownload.schedules.status',
                field: 'executionStatus',
                sortable: true
            }, {
                sortable: false,
                template: function (dataItem) {
                    var html = '<div class="pull-right">';

                    if (dataItem.type !== knownValues.scheduleType.continuous) {
                        if (dataItem.executionStatus === 'Started') {
                            html += '<button id="btnStop_{{dataItem.id}}" ng-click="vm.onStop(dataItem); $event.stopPropagation();" class="btn btn-prominent schedule-button" translate="dataDownload.schedules.stop" />';
                        }
                        html += '<button id="btnRunNow_{{dataItem.id}}" ng-if="dataItem.state!==\'disabled\'" ng-click="vm.onRunNow(dataItem); $event.stopPropagation();" class="btn btn-prominent schedule-button" translate="dataDownload.schedules.runNow" />';
                    }
                    else {
                        if (dataItem.state === 'paused') {
                            html += '<button id="btnResume_{{dataItem.id}}" ng-click="vm.onResume(dataItem); $event.stopPropagation();" class="btn btn-prominent schedule-button" translate="dataDownload.schedules.resume" />';
                        } else {
                            html += '<button id="btnPause_{{dataItem.id}}" ng-click="vm.onPause(dataItem); $event.stopPropagation();" class="btn btn-prominent schedule-button" translate="dataDownload.schedules.pause" />';
                        }
                    }
                    html += '<button id="btnDelete_{{dataItem.id}}" ng-click="vm.onDelete(dataItem); $event.stopPropagation();" class="btn btn-discard schedule-button" translate="dataDownload.schedules.delete" />';
                    html += '</div>';

                    return html;
                }
            }]
        });
    }

    function formatPreset(schedule) {
        var days;
        if (schedule.runOnDays) {
            days = schedule.runOnDays.split(',');

            if (days.length === 7) {
                return $translate.instant('dataDownload.schedules.runsDaily');
            }
            if (schedule.runOnDays === 'Sun') {
                return $translate.instant('dataDownload.schedules.runsWeekly');
            }

            var selectedDays = _.map(days, function (d) {
                return ' ' + $translate.instant('dataDownload.runOn.' + d);
            }).join();

            return $translate.instant('dataDownload.schedules.runsOn') + selectedDays;
        }
        return $translate.instant('dataDownload.schedules.runOnce');
    }

    function nextRunWithNulls(schedule) {
        if (schedule.state === vm.ScheduleStateEnum.Expired) {
            return '3000\/12\/25';
        }
        if (schedule.state === vm.ScheduleStateEnum.Purgatory) {
            return '3000\/12\/24';
        }
        return schedule.nextRun;
    }

    function setSchedulesData(data) {
        return vm.schedules = _.map(data, function (schedule) {
            var status = '';
            if (schedule.state == vm.ScheduleStateEnum.Purgatory) {
                status = $translate.instant('dataDownload.schedules.noMoreRuns');
            }
            if (schedule.state == vm.ScheduleStateEnum.Expired) {
                status = $translate.instant('dataDownload.schedules.expired');
            }
            return _.extend(schedule, {
                presetDesc: formatPreset(schedule),
                dataSourceName: $translate.instant('dataDownload.dataSource.' + schedule.dataSource),
                template: dataSourceMap.partial(schedule.dataSource, 'list'),
                downloadDesc: $translate.instant('dataDownload.downloadType.' + schedule.dataSource + '.' + schedule.downloadType),
                nextRunNullSort: nextRunWithNulls(schedule),
                statusDesc: status
            });
        });
    }

    function onAdd() {
        modalService.openModal({
            id: 'NewSchedule',
            controllerAs: 'vm'
        })
            .then(function () {
                vm.gridOptions.search();
            });
    }

    function onDelete(schedule) {
        notificationService
            .confirmDelete({
                message: 'modal.confirmDelete.message'
            })
            .then(function () {
                $http.delete(url.api('ptoaccess/Schedules/' + schedule.id))
                    .then(function (response) {
                        if (response.data.result.result === 'success') {
                            vm.schedules = _.reject(vm.schedules, function (item) {
                                return item.id === schedule.id;
                            });
                        }

                        vm.gridOptions.search();
                    });
            });
    }

    function onRunNow(schedule) {
        notificationService
            .confirm({
                message: 'dataDownload.schedules.runNowConfirmation',
                messageParams: {
                    scheduleName: schedule.name
                },
                messages: [
                    'dataDownload.schedules.runNowDescription'
                ]
            })
            .then(function () {
                $http.post(url.api('ptoaccess/Schedules/RunNow/' + schedule.id))
                    .then(function (response) {
                        if (response.data.result.result === 'success') {
                            return notificationService.success('dataDownload.schedules.runNowSuccess');
                        }
                    });
            });
    }

    function onStop(schedule) {
        notificationService
            .confirm({
                message: 'dataDownload.schedules.stopScheduleConfirmation',
                messageParams: {
                    scheduleName: schedule.name
                },
                messages: [
                    'dataDownload.schedules.stopScheduleDescription1',
                    'dataDownload.schedules.stopScheduleDescription2'
                ]
            })
            .then(function () {
                $http.post(url.api('ptoaccess/Schedules/Stop/' + schedule.id))
                    .then(function (response) {
                        if (response.data.result.result === 'success') {
                            return notificationService.success('dataDownload.schedules.stopSuccess');
                        }
                        setSchedulesData(response.data.schedules);
                    });
            });
    }

    function onPause(schedule) {
        notificationService
            .confirm({
                message: 'dataDownload.schedules.pauseScheduleConfirmation',
                messageParams: {
                    scheduleName: schedule.name
                }
            })
            .then(function () {
                $http.post(url.api('ptoaccess/Schedules/Pause/' + schedule.id))
                    .then(function (response) {
                        if (response.data.result.result === 'success') {
                            return notificationService.success('dataDownload.schedules.pauseSuccess');
                        }
                        setSchedulesData(response.data.schedules);
                    });
            });
    }

    function onResume(schedule) {
        notificationService
            .confirm({
                message: 'dataDownload.schedules.resumeScheduleConfirmation',
                messageParams: {
                    scheduleName: schedule.name
                }
            })
            .then(function () {
                $http.post(url.api('ptoaccess/Schedules/Resume/' + schedule.id))
                    .then(function (response) {
                        if (response.data.result.result === 'success') {
                            return notificationService.success('dataDownload.schedules.resumeSuccess');
                        }
                        setSchedulesData(response.data.schedules);
                    });
            });
    }
}