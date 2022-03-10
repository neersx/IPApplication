describe('Inprotech.SchemaMapping.SchemasListController', () => {
    'use strict';

    let controller: (dependencies?: any) => SchemasListController,
        notificationService: any, kendoGridBuilder: any, modalService: any, schemaDataService: ISchemaDataService, rootScope: ng.IRootScopeService, translate: any, state: any, q: ng.IQService;

    beforeEach(() => {
        angular.mock.module('Inprotech.SchemaMapping');
        schemaDataService = jasmine.createSpyObj('ISchemaDataService', ['getSchemas', 'deleteSchemaPackage', 'getMappingNamesFor']);
        state = {
            go: jasmine.createSpy('go')
        };
        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
            notificationService = $injector.get('notificationServiceMock');
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            modalService = $injector.get('modalServiceMock');
            translate = $injector.get('translateMock');
        });
    });

    let c: SchemasListController;
    beforeEach(inject(($rootScope: ng.IRootScopeService, $q: ng.IQService) => {
        controller = function (dependencies?) {
            dependencies = angular.extend({
                scope: $rootScope.$new
            }, dependencies);
            return new SchemasListController(dependencies.scope, kendoGridBuilder, modalService, notificationService, schemaDataService, translate, state);
        };
        c = controller();
        rootScope = $rootScope;
        q = $q;
    }));

    describe('add schema package', () => {
        it('should open schema editor on add', () => {
            c.onClickAdd();

            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.calls.mostRecent().args[0].id).toEqual('SchemaMappingEditor');
            expect(modalService.openModal.calls.mostRecent().args[0].controllerAs).toEqual('vm');
        });

        it('should refresh data in packages grid after addition', () => {
            (modalService.openModal as jasmine.Spy).and.returnValue(q.when({}));
            c.gridOptions.$widget.refresh = jasmine.createSpy('refresh');

            c.onClickAdd();
            rootScope.$apply();

            expect(c.gridOptions.$widget.refresh).toHaveBeenCalled();
        });
    });

    describe('edit schema package', () => {
        it('should open schema editor on edit', () => {
            c.onClickEdit({ id: 1 });

            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.calls.mostRecent().args[0].id).toEqual('SchemaMappingEditor');
            expect(modalService.openModal.calls.mostRecent().args[0].controllerAs).toEqual('vm');
            expect(modalService.openModal.calls.mostRecent().args[0].schemaId).toEqual(1);
        });

        it('should refresh data in packages grid after edit', () => {
            (modalService.openModal as jasmine.Spy).and.returnValue(q.when({}));
            c.gridOptions.$widget.refresh = jasmine.createSpy('refresh');

            c.onClickEdit({ id: 1 });
            rootScope.$apply();

            expect(c.gridOptions.$widget.refresh).toHaveBeenCalled();
        });
    });

    describe('delete schema package', () => {
        it('should confirm deletion', () => {
            (schemaDataService.deleteSchemaPackage as jasmine.Spy).and.returnValue(q.when({}));

            c.onClickDelete({ id: 1 });

            expect(schemaDataService.getMappingNamesFor).toHaveBeenCalledWith(1);
            expect(notificationService.confirmDelete).toHaveBeenCalled();
            expect(notificationService.confirmDelete.calls.mostRecent().args[0].templateUrl).toEqual('condor/classic/schemaMapping/lists/delete-schema-confirmation.html');
            expect(translate.instant).toHaveBeenCalledWith('schemaMapping.usLblDeleteMappingConfirm');
        });

        it('should make call to service for delete', () => {
            (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));

            c.onClickDelete({ id: 1 });
            rootScope.$apply();

            expect(schemaDataService.deleteSchemaPackage).toHaveBeenCalledWith(1);
        });

        it('should refresh data in packages grid after deletion', () => {
            (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));
            (schemaDataService.deleteSchemaPackage as jasmine.Spy).and.returnValue(q.when({}));
            c.gridOptions.data = jasmine.createSpy('data').and.returnValue([{ id: 1 }, { id: 99 }]);

            c.onClickDelete({ id: 1 });
            rootScope.$apply();

            expect(c.gridOptions.data).toHaveBeenCalledTimes(2);
        });
    });

    describe('add mapping', () => {
        it('should open add mapping on click of AddMapping', () => function () {
            (modalService.openModal as jasmine.Spy).and.returnValue(q.when({ result: 'success', id: 99 }));

            let schema = { id: 1 };
            c.onClickAddMapping(schema);

            expect(modalService.openModal).toHaveBeenCalled();
            expect(modalService.openModal.calls.mostRecent().args[0].id).toEqual('AddMapping');
            expect(modalService.openModal.calls.mostRecent().args[0].controllerAs).toEqual('vm');
            expect(modalService.openModal.calls.mostRecent().args[0].schemaPackage).toEqual(schema);

            rootScope.$apply();

            expect(notificationService.success).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalled();
            expect(state.go.calls.mostRecent().args[0]).toEqual('classicSchemaMapping.mapping');
            expect(state.go.calls.mostRecent().args[1].id).toEqual(99);
        });
    });
});