angular.module('inprotech.processing.policing').service('statusGraphDataAdapterService',
    function() {
        'use strict';

        var statusOrder = [{
            textKey: 'waiting-to-start',
            field: 'waitingToStart'
        }, {
            textKey: 'in-progress',
            field: 'inProgress'
        }];

        var errorStatusOrder = [{
            textKey: 'blocked',
            field: 'blocked'
        }, {
            textKey: 'failed',
            field: 'failed'
        }, {
            textKey: 'in-error',
            field: 'inError'
        }];

        function prioritiseStatus(data, isError) {
            return _.map(isError ? errorStatusOrder : statusOrder, function(s) {
                return _.pick(data[s.field], function(v) {
                    return v > 0;
                });
            });
        }

        function getCategories(isError) {
            return _.pluck(isError ? errorStatusOrder : statusOrder, 'textKey');
        }

        return {
            getCategories: getCategories,
            prioritiseStatus: prioritiseStatus
        };
    });
