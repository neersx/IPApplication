'use strict';

describe('Inprotech.Integration.PtoAccess.scheduleFrequencyController', function() {
    var controller, translate, scope;

    beforeEach(
        module(function() {
            translate = test.mock('$translate', 'translateMock');
            translate.instant = jasmine.createSpy().and.returnValue('translated text')
        }));

    beforeEach(function() {
        module('Inprotech.Integration.PtoAccess')

        inject(function($componentController, $rootScope) {
            scope = $rootScope.$new();
            controller = function(params) {
                return $componentController('ipScheduleFrequency', {
                    $scope: scope,
                    $translate: translate
                }, {
                    schedule: (params || {}).schedule || {},
                    maintenance: (params || {}).maintenance || {}
                });

            };
        })
    });

    it('should set to recurring by default, and no expiry', function() {
        var vm = controller();
        vm.$onInit();
        expect(vm.schedule.recurrence).toBe('0');
        expect(vm.schedule.runNow).toBe(true);
        expect(vm.schedule.expiresAfter).toBe(null);
        expect(vm.availableDays).toEqual(
            [{
                    day: 'Sun',
                    selected: true,
                    name: 'translated text'
                },
                {
                    day: 'Mon',
                    selected: true,
                    name: 'translated text'
                },
                {
                    day: 'Tue',
                    selected: true,
                    name: 'translated text'
                },
                {
                    day: 'Wed',
                    selected: true,
                    name: 'translated text'
                },
                {
                    day: 'Thu',
                    selected: true,
                    name: 'translated text'
                },
                {
                    day: 'Fri',
                    selected: true,
                    name: 'translated text'
                },
                {
                    day: 'Sat',
                    selected: true,
                    name: 'translated text'
                }
            ]
        );
    });

    it('should set schedule to run according to selection', function() {
        var vm = controller();
        vm.$onInit();
        scope.$digest();
        expect(vm.schedule.runOnDays).toBe('Sun,Mon,Tue,Wed,Thu,Fri,Sat');
    });

    it('should correctly indicate validity based on available days selection', function() {

        var vm = controller();
        vm.$onInit();
        _.each(vm.availableDays, function(c) {
            c.selected = false; // deselect all
        });

        scope.$digest();

        expect(vm.runOnDaysValid).toBe(false);

        _.first(vm.availableDays).selected = true;

        scope.$digest();

        expect(vm.runOnDaysValid).toBe(true);
    });
});