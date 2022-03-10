describe('dashboard', function() {
    'use strict';

    var createController;

    beforeEach(module('inprotech.dashboard'));
    beforeEach(inject(function($controller) {
        createController = function(dependencies) {
            return $controller('DashboardController', dependencies);
        };
    }));

    it('should initialize view model', function() {
        var ctrl = createController({
            appContext: {
                user: {
                    name: 'a'
                }
            }
        });
        ctrl.$onInit();

        expect(ctrl.username).toBe('a');
    });
});
