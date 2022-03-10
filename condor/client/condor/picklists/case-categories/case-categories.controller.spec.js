describe('inprotech.picklists.caseCategoriesController', function() {
    'use strict';

    var controller, scope, selectedCaseType;

    beforeEach(module('inprotech.picklists'));
    beforeEach(module('inprotech.components.picklist'));

    beforeEach(inject(function($rootScope, $controller, states) {

        scope = $rootScope.$new();
        selectedCaseType = {
            get: function() {
                return { code: 'A', value: 'Properties' };
            }
        };

        controller = function() {
            var dependencies = {
                $scope: scope,
                states: states,
                selectedCaseType: selectedCaseType
            };

            return $controller('caseCategoriesController', dependencies);
        };
    }));

    it('should initailise entry type id if state is adding', function() {
        var ctr = controller();
        var entry = {};

        ctr.init('adding', entry);
        expect(entry.caseTypeId).toEqual('A');
        expect(entry.caseTypeDescription).toEqual('Properties');
    });

    it('should not change entry type id if state is not adding', function() {
        var ctr = controller();
        var entry = {};

        ctr.init('duplicating', entry);
        expect(entry.caseTypeId).not.toEqual('A');
        expect(entry.caseTypeDescription).not.toEqual('Properties');
    });
});