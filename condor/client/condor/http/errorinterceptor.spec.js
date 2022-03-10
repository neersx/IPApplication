describe('errorinterceptor', function() {
    'use strict';

    beforeEach(module('inprotech.http'));

    var interceptor, $rootScope, notificationService;

    var status1 = 'status-1',
        status403 = 'status-403',
        status500 = 'status-500',
        status500token = 'status-500-with-token',
        statusOther = 'status-other',
        failureMsg = {
            title: 'Error',
            message: 'An unexpected error has occured. Please try again. If the problem persists, contact an Administrator',
            okButton: 'Ok'
        };

    var translations = {
        'common': {
            'errors': {
                'status-1': status1,
                'status-403': status403,
                'status-500': status500,
                'status-500-with-token': status500token + '-{{correlationId}}',
                'status-other': statusOther
            }
        }
    };

    var $translate;

    // /*eslint no-unused-vars:0 */
    beforeEach(module(function($provide, $translateProvider) {
        var $injector = angular.injector(['inprotech.mocks']);

        notificationService = {
            alert: jasmine.createSpy()
        };

        $provide.value('notificationService', notificationService);
        $provide.value('modalService', $injector.get('modalServiceMock'));

        $translateProvider.translations('en', translations);
        $translateProvider.preferredLanguage('en');

    }));

    beforeEach(inject(function(_$translate_) {
        $translate = _$translate_;
    }));

    var buildFailedResponse = function(status, token) {
        return {
            config: {
                timeout: {
                    cancelled: false
                },
                handlesError: false
            },
            status: status,
            data: {
                correlationId: token
            }
        };
    };

    beforeEach(inject(function(errorinterceptor, _$rootScope_) {
        interceptor = errorinterceptor;
        $rootScope = _$rootScope_;
    }));

    it('can get an instance', function() {
        expect(interceptor).toBeDefined();
    });

    it('notifies the right message on 403', function() {
        interceptor.responseError(buildFailedResponse(403));

        $rootScope.$digest();

        expect(notificationService.alert).toHaveBeenCalledWith({
            message: status403
        });
    });

    it('notifies the right message on 500', function() {
        interceptor.responseError(buildFailedResponse(500));

        $rootScope.$digest();

        expect(notificationService.alert).toHaveBeenCalledWith({
            message: status500
        });
    });

    it('notifies the right message on 1', function() {
        interceptor.responseError(buildFailedResponse(1));

        $rootScope.$digest();

        expect(notificationService.alert).toHaveBeenCalledWith({
            message: status1
        });
    });

    it('notifies the right message on 500 and correlationId', function() {
        interceptor.responseError(buildFailedResponse(500, 'correlationId'));

        $rootScope.$digest();

        expect(notificationService.alert).toHaveBeenCalledWith({
            message: status500token + '-correlationId'
        });
    });

    it('notifies the right message on any other error status', function() {
        interceptor.responseError(buildFailedResponse(2));

        $rootScope.$digest();

        expect(notificationService.alert).toHaveBeenCalledWith({
            message: statusOther
        });
    });

    it('notifies the right message on translation failure', function() {
        $translate.use('fr'); // translate a language we don't have translations for
        interceptor.responseError(buildFailedResponse(2));

        $rootScope.$digest();

        expect(notificationService.alert).toHaveBeenCalledWith(failureMsg);
    });

    it('does not notify if the request was cancelled', function() {
        var r = buildFailedResponse(-1);
        interceptor.responseError(r);
        $rootScope.$digest();
        expect(notificationService.alert).not.toHaveBeenCalled();
    });

    it('does not notify if handlesError is true', function() {
        var r = buildFailedResponse(500);
        r.config.handlesError = true;
        interceptor.responseError(r);
        $rootScope.$digest();
        expect(notificationService.alert).not.toHaveBeenCalled();
    });

    it('does not notify if handlesError returns true', function() {
        var r = buildFailedResponse(500);
        r.config.handlesError = function() {
            return true;
        };
        interceptor.responseError(r);
        $rootScope.$digest();
        expect(notificationService.alert).not.toHaveBeenCalled();
    });

    it('does notify if handlesError returns false', function() {
        var r = buildFailedResponse(500);
        r.config.handlesError = function() {
            return false;
        };
        interceptor.responseError(r);
        $rootScope.$digest();
        expect(notificationService.alert).toHaveBeenCalledWith({
            message: status500
        });
    });

    it('calls handlesError with correct parameters', function() {
        var r = buildFailedResponse(500);
        r.config.handlesError = jasmine.createSpy().and.returnValue(true);
        interceptor.responseError(r);
        $rootScope.$digest();
        expect(r.config.handlesError).toHaveBeenCalledWith(r.data, 500, r);
    });
});
