describe('inprotech.picklists.instructionsController', function() {
    'use strict';

    var controller, http, scope, selectedInstructionType;

    beforeEach(module('inprotech.picklists'));
    beforeEach(module('inprotech.components.picklist'));

    beforeEach(inject(function($httpBackend, $rootScope, $controller, states) {

        http = $httpBackend;
        scope = $rootScope.$new();
        selectedInstructionType = {
            get: function() {
                return 'selectedInstructionType';
            }
        };

        controller = function() {
            var dependencies = {
                $scope: scope,
                states: states,
                selectedInstructionType: selectedInstructionType
            };

            return $controller('instructionsController', dependencies);
        };
    }));

    it('should get instruction types', function() {
        var instructionTypes = [];
        http.whenGET('api/picklists/instructions/instructionTypes')
            .respond(function() {
                return [200, instructionTypes, {}];
            });

        var ctr = controller();
        http.flush();

        expect(ctr.instructionTypes).toEqual(instructionTypes);
    });

    it('should initailise entry type id if state is adding', function() {
        var ctr = controller();
        var entry = {};

        ctr.init('adding', entry);
        expect(entry.typeId).toEqual('selectedInstructionType');
    });

    it('should not change entry type id if state is not adding', function() {
        var ctr = controller();
        var entry = {};

        ctr.init('duplicating', entry);
        expect(entry.typeId).not.toEqual('selectedInstructionType');
    });
});
