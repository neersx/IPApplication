angular.module('inprotech.processing.policing').service('rateGraphItemFormatterService',
    function($filter, dateService) {
        'use strict';

        function format(items) {
            var formatTimeOnly = 'H:mm';
            var today = moment().startOf('day');

            _.each(items, function(d) {
                var label = $filter('date')(d.timeSlot, formatTimeOnly);
                if (moment(d.timeSlot).startOf('day').diff(today, 'days') !== 0) {
                    label = label + '\n' + $filter('date')(d.timeSlot, dateService.dateFormat);
                }
                d.timeSlotLabel = label;
            });

            return items;
        }

        return {
            format: format
        };
    });