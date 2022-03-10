describe('inprotech.picklists.instructionTypesController', function() {
    'use strict';

    var controller, http, scope;

    beforeEach(module('inprotech.picklists'));

    beforeEach(inject(function($httpBackend, $rootScope, $controller) {

        http = $httpBackend;
        scope = $rootScope.$new();
        scope.vm = {};

        controller = function() {
            var dependencies = {
                $scope: scope
            };

            return $controller('instructionTypesController', dependencies);
        };

    }));

    it('should get name types', function() {
        var nameTypes = [];
        http.whenGET('api/picklists/instructionTypes/nameTypes')
            .respond(function() {
                return [200, nameTypes, {}];
            });

        var ctr = controller();
        http.flush();

        expect(ctr.nameTypes).toEqual(nameTypes);
    });
});
