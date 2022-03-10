describe('InheritanceBreakConfirmationController', function() {
    'use strict';

    var controller, modalMock, viewData;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            modalMock = test.mock('$uibModalInstance', 'ModalInstanceMock');
        })

        inject(function($controller) {
            controller = function() {
                viewData = {
                    id: 2,
                    context: 'abc'
                };

                var returnController = $controller('InheritanceBreakConfirmationController', {
                    options: viewData
                });

                return returnController;
            };
        });
    });

    it('should initialise', function() {
        var c = controller();
        expect(c.parent).toBe(viewData.parent);
        expect(c.context).toEqual('workflows.inheritanceBreakConfirmation.abc');
    });

    it('should close the modal on proceed', function() {
        var c = controller();

        c.proceed();
        expect(modalMock.close).toHaveBeenCalled();
    });

    it('should dismiss the modal on cancel', function() {
        var c = controller();

        c.cancel();
        expect(modalMock.dismiss).toHaveBeenCalledWith('Cancel');
    });
});
