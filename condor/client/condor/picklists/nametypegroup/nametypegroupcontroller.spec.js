describe('inprotech.picklists.nametypegroupController', function() {
    'use strict';

    var httpMock, scope;

    beforeEach(function() {
        module('inprotech.picklists');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);
            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function($rootScope, $controller) {
        scope = $rootScope.$new();
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
            $http: httpMock
        };

        return $controller('tagsController', dependencies);
    }));

    it('should call search when success', function() {
        var entry = {
            $response: {
                data: {
                    result: 'success'
                }
            }
        };

        var response = {};
        var callback = function($scope, response) {
            return response.data;
        }

        scope.vm.confirmAfterSave(entry, response, callback);

    });
});