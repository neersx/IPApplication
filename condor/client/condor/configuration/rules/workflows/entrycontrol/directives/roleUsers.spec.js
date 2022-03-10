describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlUserAccessUsers', function() {
    'use strict';

    var controller, service, promiseMock;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            service = test.mock('workflowsEntryControlService');
            promiseMock = test.mock('promise');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            var scope = $rootScope.$new();
            scope.roleId = -1;

            var c = $componentController('ipWorkflowsEntryControlUserAccessUsers', {
                $scope: scope
            });
            c.$onInit();
            return c;
        };
    }));

    it('should get users for role', function() {
        var returnData = ['a','b','c'];
        service.getUsers = promiseMock.createSpy(returnData);
        var c = controller();

        expect(service.getUsers).toHaveBeenCalledWith(-1);
        expect(c.users).toBe(returnData);
    });
});
