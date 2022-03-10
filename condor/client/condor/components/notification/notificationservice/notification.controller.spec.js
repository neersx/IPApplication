describe('notification controller inprotech.components.notification.NotificationController', function() {
    'use strict';

    beforeEach(module('inprotech.components.notification'));

    beforeEach(module(function($provide) {
        var $injector = angular.injector(['inprotech.mocks']);
        $provide.value('$uibModalInstance', $injector.get('ModalInstanceMock'));
        $provide.value('modalService', $injector.get('modalServiceMock'));
    }));

    var controller, scope, uibModalInstance;
    beforeEach(inject(function($rootScope, $controller, $uibModalInstance) {
        scope = $rootScope.$new();
        uibModalInstance = $uibModalInstance;

        controller = function(options) {
            return $controller('NotificationController', {
                $scope: scope,
                options: options
            });
        };
    }));

    describe('init', function() {
        it('should initialise scope options', function() {
            var options = {
                message: 'test'
            };

            controller(options);
            expect(scope.options.message).toBe(options.message);
        });
    });

    describe('confirm', function() {
        it('should close modal with result', function() {
            controller();
            scope.confirm();

            expect(uibModalInstance.close).toHaveBeenCalled();
        });
    });

    describe('close', function() {
        it('should dismiss modal', inject(function($timeout) {
            controller();
            scope.cancel();

            $timeout.flush();

            expect(uibModalInstance.dismiss).toHaveBeenCalled();
        }));
    });
});
