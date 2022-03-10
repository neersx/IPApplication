describe('inprotech.processing.policing.ipPolicingRequestLogerrorController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, modalService;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing', 'inprotech.mocks.components.grid']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });

    beforeEach(inject(function($controller, $rootScope) {
        scope = $rootScope.$new();
        scope.data = {};
        controller = function() {
            return $controller('ipPolicingRequestLogerrorController', { $scope: scope });
        };
    }));

    describe('initialize view model', function() {
        it('should initialize grid builder options', function() {
            var c = controller();
            c.$onInit();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });

    describe('click show all errors', function() {
        it('should call modalService', function() {
            var c = controller();
            c.$onInit();
            c.viewErrors();
            expect(modalService.open).toHaveBeenCalledWith('PolicingRequestLogErrors', scope);
        });
    });
});
