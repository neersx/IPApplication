describe('Inprotech.SchemaMapping.MappingsListController', () => {
    'use strict';

    let controller: (dependencies?: any) => MappingsListController,
        notificationService: any, kendoGridBuilder: any, schemaDataService: ISchemaDataService, rootScope: ng.IRootScopeService, q: ng.IQService;

    beforeEach(() => {
        angular.mock.module('Inprotech.SchemaMapping');
        schemaDataService = jasmine.createSpyObj('ISchemaDataService', ['deleteMapping', 'getMappings', 'mappingsModified']);
        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
            notificationService = $injector.get('notificationServiceMock');
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
        });
    });

    let c: MappingsListController;
    beforeEach(inject(($rootScope: ng.IRootScopeService, $q: ng.IQService) => {
        controller = function (dependencies?) {
            dependencies = angular.extend({
                scope: $rootScope.$new()
            }, dependencies);
            return new MappingsListController(dependencies.scope, kendoGridBuilder, notificationService, schemaDataService);
        };
        c = controller();
        rootScope = $rootScope;
        q = $q;
    }));

    it('should initialize kendo grid', () => {
        expect(c.gridOptions).not.toBe(null);
    });

    describe('delete mapping', () => {
        it('should confirm deletion', () => {
            (schemaDataService.deleteMapping as jasmine.Spy).and.returnValue(q.when({}));

            c.onDelete({ id: 1 });

            expect(notificationService.confirmDelete).toHaveBeenCalled();
            expect(notificationService.confirmDelete.calls.mostRecent().args[0].message).toEqual('modal.confirmDelete.message');
        });

        it('should make call to service for delete', () => {
            (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));

            c.onDelete({ id: 1 });
            rootScope.$apply();

            expect(schemaDataService.deleteMapping).toHaveBeenCalledWith(1);
        });

        it('should refresh data in packages grid after deletion', () => {
            (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));
            (schemaDataService.deleteMapping as jasmine.Spy).and.returnValue(q.when({}));
            c.gridOptions.data = jasmine.createSpy('data').and.returnValue([{ id: 1 }, { id: 99 }]);

            c.onDelete({ id: 1 });
            rootScope.$apply();

            expect(notificationService.success).toHaveBeenCalled();
        });
    });
});