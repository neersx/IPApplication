describe('ipDefaultJurisdiction', function() {
    'use strict';

    var controller;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        inject(function($componentController) {
            controller = function(params) {
                var c = $componentController('ipDefaultJurisdiction', {}, {
                    results: params
                });
                c.$onInit();
                return c;
            }
        });
    });

    it('should display the default jurisdiction ', function() {
        var params = [{
                "isDefaultJurisdiction": true
            }, {
                "isDefaultJurisdiction": true
            }];

        var c = controller(params);
        expect(c.isDefaultJurisdiction()).toBe(true);
    });

    it('should not display the default jurisdiction ', function() {
        var params = [{
                "isDefaultJurisdiction": true
            }, {
                "isDefaultJurisdiction": false
            }];

        var c = controller(params);
        expect(c.isDefaultJurisdiction()).toBe(false);
    });
});
