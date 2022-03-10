describe('notificationService', function() {
    'use strict';

    var _notificationsService;
    var _location;
    var _httpBackend;
    var _payload = 'a';

    beforeEach(module('Inprotech.CaseDataComparison'));

    beforeEach(inject(function($location, $injector, notificationsService) {
        _location = $location;
        _httpBackend = $injector.get('$httpBackend');
        _notificationsService = notificationsService;
    }));

    describe('get method', function() {
        describe('without a case list', function() {
            it('should return notifications from inbox/notifications api', function() {
                _httpBackend.whenPOST('api/casecomparison/inbox/notifications')
                    .respond(_payload);

                _notificationsService.get({})
                    .then(function(res) {
                        expect(_payload).toBe(res);
                    });

                _httpBackend.flush();
            });
        });

        describe('with a case list', function() {
            it('should return notifications from inbox/cases api with temporary storage id', function() {
                _location.search = function() {
                    return {
                        caselist: null,
                        ts: 1
                    };
                };

                _httpBackend.whenPOST('api/casecomparison/inbox/cases')
                    .respond(_payload);

                _notificationsService.get({})
                    .then(function(res) {
                        expect(_payload).toBe(res);
                    });

                _httpBackend.flush();
            });

            it('should return notifications from inbox/cases api with caselist', function() {
                _location.search = function() {
                    return {
                        caselist: '-587',
                        ts: null
                    };
                };

                _httpBackend.whenPOST('api/casecomparison/inbox/cases')
                    .respond(_payload);

                _notificationsService.get({})
                    .then(function(res) {
                        expect(_payload).toBe(res);
                    });

                _httpBackend.flush();
            });

        });

        describe('with a execution list', function() {
            it('should return notifications from executions api', function() {
                _location.search = function() {
                    return {
                        se: 1,
                        dataSource: 'a'
                    };
                };

                _httpBackend.whenPOST('api/casecomparison/inbox/executions')
                    .respond(_payload);

                _notificationsService.get({})
                    .then(function(res) {
                        expect(_payload).toBe(res);
                    });

                _httpBackend.flush();
            });
        });
        
        afterEach(function() {
            _httpBackend.verifyNoOutstandingExpectation();
            _httpBackend.verifyNoOutstandingRequest();
        });
    });
});
