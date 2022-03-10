angular.module('Inprotech.Integration.PtoAccess')
    .component('ipScheduleFrequency', {
        templateUrl: 'condor/classic/integration/ptoaccess/schedule-frequency-component.html',
        bindings: {
            schedule: '<',
            maintenance: '='
        },
        controllerAs: 'vm',
        controller: function ($scope, $translate, knownValues) {
            'use strict';

            var vm = this;
            var date = new Date();
            var initialDate = toISO8601(date);

            vm.$onInit = onInit;

            function onInit() {

                vm.recurrence = knownValues.recurrence;
                vm.schedule.recurrence = vm.recurrence.recurring;
                vm.schedule.runNow = true;
                vm.schedule.expiresAfter = null;
                vm.schedule.runOn = initialDate;
                vm.runOn = date;
                vm.recurrenceChanged = recurrenceChanged;
                vm.runNowChanged = runNowChanged;
                vm.timeSelectionChanged = timeSelectionChanged;
                vm.timeEdited = timeEdited;
                vm.dateEdited = dateEdited;
                vm.availableDays = _.map(knownValues.days, function (d) {
                    return {
                        day: d,
                        selected: true,
                        name: $translate.instant('dataDownload.runOn.' + d)
                    };
                });

                vm.selectedHour = vm.selectedMinutes = '00';
            }

            function timeEdited() {
                return (vm.selectedHour + ':' + vm.selectedMinutes) !== '00:00';
            }

            function dateEdited() {
                return (!vm.runOn || toISO8601(vm.runOn) !== initialDate);
            }

            function recurrenceChanged() {
                vm.schedule.continuousDuplicate = false;
                runNowChanged();
            }

            function runNowChanged() {
                if (vm.schedule.recurrence === knownValues.recurrence.recurring) {
                    vm.runOn = date;
                    vm.selectedHour = vm.selectedMinutes = '00';
                    timeSelectionChanged();
                }
            }

            function timeSelectionChanged() {
                vm.schedule.startTime = vm.selectedHour + ':' + vm.selectedMinutes;
            }

            function toISO8601(date) {
                if (!date) {
                    return null;
                }
                return new moment(date).format('YYYY-MM-DD');
            }

            $scope.$watch('vm.availableDays|filter:{selected:true}', function (ad) {
                vm.runOnDaysValid = ((vm.schedule.recurrence === knownValues.recurrence.recurring) && ad.length > 0) || (vm.schedule.recurrence !== knownValues.recurrence.recurring);
                vm.schedule.runOnDays = ad.map(function (d) {
                    return d.day;
                }).join();
            }, true);

            $scope.$watch('vm.runOn', function () {
                vm.schedule.runOn = toISO8601(vm.runOn);
            });

            $scope.$watch('vm.expiresAfter', function () {
                vm.schedule.expiresAfter = toISO8601(vm.expiresAfter);
            });
        }
    });