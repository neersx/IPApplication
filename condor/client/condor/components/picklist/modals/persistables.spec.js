describe('Service inprotech.components.picklist.persistables', function() {
    'use strict';

    var service, api = {};

    beforeEach(module('inprotech.components.picklist'));

    beforeEach(module(function($provide) {
        var $injector = angular.injector(['inprotech.mocks']);

        api = $injector.get('BasePicklistApiMock');
        $provide.value('picklistMaintenanceService', api);
        $provide.value('templateResolver', $injector.get('TemplateResolverMock'));

    }));

    beforeEach(inject(function(persistables) {
        service = persistables;
    }));

    it('should have a prepare method', function() {
        expect(service).toBeDefined();
        expect(service.prepare).toBeDefined();
    });

    it('should return item for maintenance', function() {
        var r = service.prepare('Some', 'adding', null, 'id');
        expect(r).toBeDefined();
    });

    it('should return item with the state', function() {
        var r = service.prepare('Some', 'adding', null, 'id');
        expect(r.state).toEqual('adding');
    });

    it('should return item with maintenance template', function() {
        var r = service.prepare('Some', 'adding', null, 'id');
        expect(r.template).toEqual('some template');
    });

    it('should call $build for \'adding\' state', function() {
        var r = service.prepare('Some', 'adding', null, 'id', true);
        expect(api.$build).toHaveBeenCalled();
        expect(r.entry).toBeDefined();
    });

    it('should call $build for \'duplicating\' state', function() {
        var original = {};
        var r = service.prepare('Some', 'duplicating', original, 'id', []);
        expect(api.$build).toHaveBeenCalled();
        expect(r.entry).toBeDefined();
    });

    it('should call $find \'updating\' state, to update a fresh copy', function() {
        var original = {
            id: 5
        };

        api.$find = function() {
            return {
                id: 5
            };
        };

        spyOn(api, '$find').and.callThrough();

        var r = service.prepare('Some', 'updating', original, 'id');
        expect(api.$find).toHaveBeenCalled();
        expect(r.entry).toBeDefined();
    });

    it('should call $find \'deleting\' state, to delete a fresh copy', function() {
        var original = {
            id: 5
        };

        api.$find = function() {
            return {
                id: 5
            };
        };

        spyOn(api, '$find').and.callThrough();

        var r = service.prepare('Some', 'deleting', original, 'id');
        expect(api.$find).toHaveBeenCalled();
        expect(r.entry).toBeDefined();
    });

    it('should call $find \'viewing\' state', function() {
        var original = {
            id: 5
        };

        api.$find = function() {
            return {
                id: 5
            };
        };

        spyOn(api, '$find').and.callThrough();

        var r = service.prepare('Some', 'viewing', original, 'id');
        expect(api.$find).toHaveBeenCalled();
        expect(r.entry).toBeDefined();
    });

});
