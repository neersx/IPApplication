angular.module('inprotech.processing.policing')
    .factory('requestReminderHelper', function(dateHelper) {
        'use strict';
        var vm = {};
        return {
            init: function(request) {
                vm.request = request;
            },
            setForDays: function(startDate, endDate) {
                if (this.positiveOrEmptyDays() && startDate && endDate) {
                    var dayDiff = moment(endDate).diff(moment(startDate), 'days') + 1;
                    vm.request.forDays = dayDiff > 0 ? dayDiff : null;
                }
            },
            positiveOrEmptyDays: function() {
                return !vm.request.forDays || vm.request.forDays > 0;
            },
            setDatesValidityByDays: function(form, field, dateVal) {
                var errorKey = 'policing.request.maintenance.sections.eventsReminder.errors.daysNegative';
                var isInValid = function(newVal) {
                    return !(vm.request.forDays < 0 && newVal);
                };
                var setFieldValidity = function(field, validity) {
                    if (field === 'startDate') {
                        form.startDate.$setValidity(errorKey, validity);
                    }
                    if (field === 'endDate') {
                        form.endDate.$setValidity(errorKey, validity);
                    }
                };

                if (field) {
                    setFieldValidity(field, isInValid(dateVal));
                } else {
                    setFieldValidity('startDate', isInValid(vm.request.startDate));
                    setFieldValidity('endDate', isInValid(vm.request.endDate));
                }
            },
            addDays: dateHelper.addDays,
            convertForDatePicker: dateHelper.convertForDatePicker,
            areDatesEqual: dateHelper.areDatesEqual
        };
    });