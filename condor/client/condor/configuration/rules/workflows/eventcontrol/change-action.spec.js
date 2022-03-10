describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlChangeAction', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function(viewData) {
            var scope = $rootScope.$new();
            var baseViewData = {
                canEdit: true,
                changeAction: {
                    code: -333,
                    value: "ABC"
                }
            };
            _.extend(baseViewData, viewData);
            var topic = {
                params: {
                    viewData: baseViewData
                }
            };
            var c = $componentController('ipWorkflowsEventControlChangeAction', {
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

            expect(c.changeAction.code).toEqual(-333);
            expect(c.changeAction.value).toEqual("ABC");
            expect(c.canEdit).toEqual(true);
            expect(c.parentData).toEqual({});
        });

        it('should initialise parentData correctly', function() {
            var viewData = {
                isInherited: true,
                parent: {
                    changeAction: { 'abc': 'def' }
                }
            }

            var c = controller(viewData);

            expect(c.parentData).toBe(viewData.parent.changeAction);
        });
    });

    describe('topic functions', function() {
        it('gets form data for save', function() {
            var c = controller();
            c.changeAction.openAction = {
                code: 'a'
            };
            c.changeAction.closeAction = null;
            c.changeAction.relativeCycle = 3;

            var formData = c.topic.getFormData();
            expect(formData).toEqual({
                openActionId: 'a',
                closeActionId: null,
                relativeCycle: 3
            });
        });

    });

    describe('isCloseActionEmpty', function() {
        it('should return true if the object is null or the key is null', function() {
            var c = controller();
            c.changeAction.closeAction = {
                key: null,
                value: 'abc'
            };
            var result = c.isCloseActionEmpty();
            expect(result).toEqual(true);

            c.changeAction.closeAction = null;
            result = c.isCloseActionEmpty();
            expect(result).toEqual(true);
        });

        it('should return false if change action is not empty', function() {
            var c = controller();
            c.changeAction.closeAction = {
                key: 'a',
                value: 'abc'
            };
            var result = c.isCloseActionEmpty();
            expect(result).toEqual(false);
        });
    });

    it('isReletiveCycleDisabled should return correct value', function() {
        var c = controller();
        c.canEdit = false
        c.isCloseActionEmpty = _.constant(false);
        var result = c.isReletiveCycleDisabled();
        expect(result).toEqual(true);

        c.canEdit = true
        c.isCloseActionEmpty = _.constant(true);
        result = c.isReletiveCycleDisabled();
        expect(result).toEqual(true);

        c.canEdit = true
        c.isCloseActionEmpty = _.constant(false);
        result = c.isReletiveCycleDisabled();
        expect(result).toEqual(false);

    });

    describe('onCloseActionChange', function() {
        var c;
        beforeEach(function() {
            c = controller();
            c.form = {
                relativeCycle: {
                    $setDirty: jasmine.createSpy().and.callThrough()
                }
            }
        });

        it('should set relative cycle as null', function() {
            c.isCloseActionEmpty = _.constant(true);
            c.onCloseActionChange();
            expect(c.form.relativeCycle.$setDirty).toHaveBeenCalled();
            expect(c.changeAction.relativeCycle).toEqual(null);
        });

        it('should reset relative cycle', function() {
            c.isCloseActionEmpty = _.constant(false);
            c.changeAction = {
                closeAction: {
                    cycles: 1
                },
                relativeCycle: 2
            };
            c.onCloseActionChange();
            expect(c.changeAction.relativeCycle).toEqual(3);

            c.changeAction.closeAction.cycles = 3;
            c.onCloseActionChange();
            expect(c.changeAction.relativeCycle).toEqual(0);
        });
    });

    describe('isInheritedMethod', function() {
        it('should return true if parent and child are equal', function() {
            var c = controller();
            c.parentData = { 'abc': 'def' };
            c.changeAction = { 'abc': 'def' };
            expect(c.isInherited()).toEqual(true);
        });

        it('should return false if parent and child are not equal', function() {
            var c = controller();
            c.parentData = { 'abc': 'defg' };
            c.changeAction = { 'abc': 'def' };
            expect(c.isInherited()).toEqual(false);

            c.parentData = {};
            c.changeAction = { 'abc': null };
            expect(c.isInherited()).toEqual(false);
        });
    });
});