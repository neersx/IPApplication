describe('inprotech.processing.policing.PolicingNextRunTimeController', function() {
    'use strict';

    var scope, _moment, controller, modalService, defaultMoment;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing']);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });
    /*eslint-disable */
    beforeEach(inject(function() {
        defaultMoment = window.moment;

        window.moment = _moment = function() {
            return _moment;
        };

        _moment.utc = function() {
            return _moment;
        };

        _moment.toDate = function() {
            return new Date();
        };

        _moment.add = function() {
            return _moment;
        };

        _moment.format = function() {
            return '';
        };

        _moment.minutes = function() {
            return 0;
        };
    }));

    afterEach(function() {
        window.moment = defaultMoment;
    });
    /*eslint-enable */

    beforeEach(inject(function($controller, $rootScope) {

        scope = $rootScope.$new();

        controller = function() {
            return $controller('PolicingNextRunTimeController', {
                $scope: scope
            });
        };
    }));

    describe('initializes accordingly', function() {
        it('should initialize without a date', function() {
            controller();

            expect(scope.selectedDate).not.toBeDefined();

            expect(scope.selectedHour).toEqual('00');

            expect(scope.selectedMinutes).toEqual('00');
        });

        it('should initialize with a date', function() {

            scope.currentDate = '2016-07-08T04:00:00';

            var utc = spyOn(_moment, 'utc').and.callThrough();

            var fmt = spyOn(_moment, 'format').and.callThrough();

            controller();

            expect(utc).toHaveBeenCalledWith('2016-07-08T04:00:00');

            expect(fmt).toHaveBeenCalledWith('HH');

            expect(fmt).toHaveBeenCalledWith('mm');
        });
    });

    describe('dismiss', function() {
        it('should dismiss modal', function() {
            controller();

            modalService.close = jasmine.createSpy('modal close spy');

            scope.dismissAll();

            expect(modalService.close).toHaveBeenCalledWith('NextRunTime');
        });
    });

    describe('save', function() {
        it('should emit selected value', function() {

            controller();

            modalService.close = jasmine.createSpy('modal close spy');

            spyOn(scope, '$emit');

            scope.selectedDate = new Date(2016, 8, 9);
            scope.selectedHour = '23';
            scope.selectedMinutes = '43';
            scope.save();

            expect(scope.$emit).toHaveBeenCalledWith('nextRunTime', '2016-9-9T23:43');
        });
    });
});