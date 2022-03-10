describe('inprotech.picklists.tagsController', function() {
    'use strict';

    var httpMock, scope, notificationSvc;

    beforeEach(function() {
        module('inprotech.picklists');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.components.notification']);
            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
            $provide.value('notificationService', $injector.get('notificationServiceMock'));
        });
    });

    beforeEach(inject(function($rootScope, $controller, notificationService) {
        scope = $rootScope.$new();
        notificationSvc = notificationService;

        scope = angular.extend(scope, {
            vm: {
                entry: {}
            }
        });

        scope.vm.confirmAfterSave = function() {
            return;
        };

        var dependencies = {
            $scope: scope,
            $http: httpMock,
            notificationService: notificationSvc
        };

        return $controller('tagsController', dependencies);
    }));

    it('should call update api when confirm', function() {
        var entry = {
            $response: {
                data: {
                    result: 'confirmation'
                }
            }
        };

        var response = {};
        var callback = function($scope, response) {
            return response.data;
        }

        scope.vm.confirmAfterSave(entry, response, callback);

        expect(notificationSvc.confirm).toHaveBeenCalled();
        expect(httpMock.put).toHaveBeenCalledWith('api/picklists/tags/updateconfirm', entry);

    });
});