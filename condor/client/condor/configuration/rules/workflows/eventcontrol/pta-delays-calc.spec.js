describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlPtaDelaysCalc', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            var scope = $rootScope.$new();
            var topic = {
                params: {
                    viewData: {
                        canEdit: true,
                        ptaDelay: 'ipOfficeDelay',
                        isInherited: true,
                        parent: {
                            ptaDelay: 'ipOfficeDelay'
                        }
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlPtaDelaysCalc', {
                $scope: scope
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();

            expect(c.ptaDelay).toEqual('ipOfficeDelay');
            expect(c.canEdit).toEqual(true);
            expect(c.parentData.ptaDelay).toEqual('ipOfficeDelay');
        });
    });

    describe('isDirty', function(){
        var ctrl;
        beforeEach(function(){
            ctrl = controller();
            ctrl.form = {
                $dirty: false
            };
        });

        it('should return form dirty', function(){
            expect(ctrl.topic.isDirty()).toBe(false);
            ctrl.form.$dirty = true;
            expect(ctrl.topic.isDirty()).toBe(true);
        });
    });

    describe('getFormData', function(){
        it('returns report', function(){
            var c = controller();
            var r = c.topic.getFormData();
            expect(r.PtaDelaySelection).toBe('ipOfficeDelay');
        }); 
    });
});
