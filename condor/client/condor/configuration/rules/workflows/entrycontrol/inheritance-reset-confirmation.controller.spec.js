describe('InheritanceResetConfirmationController', function() {
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
                    items: [{
                        id: 1
                    }],
                    parent: {
                        id: 2
                    },
                    context: 'abc'
                };

                var returnController = $controller('InheritanceResetConfirmationController', {
                    viewData: viewData
                });

                return returnController;
            };
        });
    });

    it('should initialise', function() {
        var c = controller();
        expect(c.items).toBe(viewData.items);
        expect(c.parent).toBe(viewData.parent);
        expect(c.context).toEqual('workflows.inheritanceResetConfirmation.abc');
        expect(c.applyChangesToChildren).toEqual(true);
    });

    it('should close the modal on proceed', function() {
        var c = controller();

        c.proceed();
        expect(modalMock.close).toHaveBeenCalledWith(true);
        c.applyChangesToChildren = false;
        c.proceed();
        expect(modalMock.close).toHaveBeenCalledWith(false);
    });

    it('should dismiss the modal on cancel', function() {
        var c = controller();

        c.cancel();
        expect(modalMock.dismiss).toHaveBeenCalledWith('Cancel');
    });
});
