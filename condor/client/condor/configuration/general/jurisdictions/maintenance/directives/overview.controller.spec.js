describe('inprotech.configuration.general.jurisdictions.JurisdictionOverviewController', function() {
    'use strict';

    var controller, extObjFactory;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        inject(function($controller) {
            var $injector = angular.injector(['inprotech.core.extensible']);
            extObjFactory = $injector.get('ExtObjFactory');

            controller = function() {
                var c = $controller('JurisdictionOverviewController', {
                    $scope: {
                        viewData: {
                            dateCommenced: '1904-02-13',
                            dateCeased: '',
                            canEdit: false
                        }
                    },
                    ExtObjFactory: extObjFactory
                }, {
                    topic: {}
                });

                c.$onInit();
                return c;
            };
        });
    });

    it('should initialise the properties', function() {
        var c = controller();
        expect(c.form).toBeDefined();
        expect(c.formData).toBeDefined();
        expect(c.topic.isDirty).toBeDefined();
        expect(c.topic.discard).toBeDefined();
        expect(c.topic.getFormData).toBeDefined();
        expect(c.topic.afterSave).toBeDefined();
        expect(c.topic.hasError).toBeDefined();
        expect(c.formData.dateCommenced.getFullYear()).toBe(1904);
        expect(c.formData.dateCommenced.getMonth()).toBe(1);
        expect(c.formData.dateCommenced.getDate()).toBe(13);
        expect(c.formData.dateCeased).toBe(null);
    });

    it('hasError should only return true if invalid and dirty', function() {
        var c = controller();
        expect(dirtyCheck(c, true, true)).toBe(true);
        expect(dirtyCheck(c, false, true)).toBe(false);
        expect(dirtyCheck(c, true, false)).toBe(false);
        expect(dirtyCheck(c, false, false)).toBe(false);
    });

    it('should disable fields when in view only mode', function() {
        var c = controller();
        expect(c.formData.canEdit).toBe(false);
    });

    function dirtyCheck(c, invalid, dirty) {
        c.form = {
            $invalid: invalid,
            $dirty: dirty
        };
        return c.topic.hasError();
    }
});
