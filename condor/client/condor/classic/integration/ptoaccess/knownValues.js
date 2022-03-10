angular.module('Inprotech.Integration.PtoAccess')
    .factory('knownValues', function() {
        'use strict';
        return {
            dataSources: {
                UsptoPrivatePair: 'UsptoPrivatePair',
                UsptoTsdr: 'UsptoTsdr',
                Epo: 'Epo',
                Innography: 'Innography'
            },

            schedulePresets: {
                Daily: 'Daily',
                Weekly: 'Weekly',
                OnSelectedDays: 'OnSelectedDays'
            },

            recurrence: {
                recurring: '0',
                runOnce: '1',
                continuous: '2'
            },

            scheduleType: {
                scheduled: 0,
                onDemand: 1,
                retry: 2,
                continuous: 3
            },

            downloadTypes: {
                All: 'All',
                ApplicationsWithStatusChanges: 'StatusChange',
                ListOfOutgoingCorrespondence: 'Documents',
                SavedQuery: 'SavedQuery'
            },
            
            days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        };
    });