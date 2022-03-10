angular.module('Inprotech.CaseDataComparison')
    .factory('legacyDataAdaptor', function() {
        'use strict';

        var requiresAdaptor = function(data) {
            if (data.case && data.case.ref && data.case.ref.uspto) {
                return true;
            }
            return false;
        };

        var convert = function(data, name) {
            if (data[name]) {
                if (data[name].inprotech) {
                    data[name].ourValue = data[name].inprotech;
                }
                if (data[name].uspto) {
                    data[name].theirValue = data[name].uspto;
                }
            }
            return data[name];
        };

        var adapt = function(data) {
            if (data.case) {
                data.case.ref = convert(data.case, 'ref');
                data.case.title = convert(data.case, 'title');
                data.case.status = convert(data.case, 'status');
                data.case.statusDate = convert(data.case, 'statusDate');
                data.case.localClasses = convert(data.case, 'localClasses');
            }

            if (data.caseNames) {
                data.caseNames = _.map(data.caseNames, function(cn) {
                    return {
                        syncId: cn.syncId,
                        nameType: cn.nameType,
                        name: convert(cn, 'name'),
                        address: convert(cn, 'address')
                    };
                });
            }

            if (data.officialNumbers) {
                data.officialNumbers = _.map(data.officialNumbers, function(on) {
                    return {
                        syncId: on.syncId,
                        numberType: on.numberType,
                        number: convert(on, 'number'),
                        'event': on.event,
                        eventDate: convert(on, 'eventDate')
                    };
                });
            }

            if (data.events) {
                data.events = _.map(data.events, function(e) {
                    return {
                        syncId: e.syncId,
                        eventType: e.eventType,
                        cycle: e.cycle,
                        eventDate: convert(e, 'eventDate')
                    };
                });
            }

            return data;
        };

        return {
            adapt: function(data) {
                if (data.messages || !requiresAdaptor(data)) {
                    return data;
                }

                return adapt(data);
            }
        };
    });
