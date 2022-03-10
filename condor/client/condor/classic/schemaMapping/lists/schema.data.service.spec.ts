describe('Inprotech.SchemaMapping.SchemaEditorController', () => {
    'use strict';

    let service: (dependencies?: any) => ISchemaDataService,
        http: any;
    let s: ISchemaDataService;

    beforeEach(() => {
        angular.mock.module('Inprotech.SchemaMapping');

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
            http = $injector.get('httpMock');
        });
    });

    beforeEach(inject((url: any) => {
        service = function () {
            return new SchemaDataService(http, url);
        };
    }));

    describe('Schema related', () => {
        it('getSchemas should call api to get schemas', () => {
            s = service();

            s.getSchemas();
            expect(http.get).toHaveBeenCalledWith('api/schemapackage/list');
        });

        it('addOrGetSchemaPackage should call api to create or get schema package', () => {
            s = service();

            s.addOrGetSchemaPackage(100);
            expect(http.get).toHaveBeenCalledWith('api/schemapackage/100/details');
        });

        it('getRootNodesForSchemaPackage should call api to get root nodes for package', () => {
            s = service();

            s.getRootNodesForSchemaPackage(100);
            expect(http.get).toHaveBeenCalledWith('api/schemapackage/100/roots');
        });

        it('updateSchemaPackage should call api to update package', () => {
            s = service();

            s.updateSchemaPackage(100, 'newName');
            expect(http.put).toHaveBeenCalledWith('api/schemapackage/100/name', { name: 'newName' });
        });

        it('deleteSchemaPackage should call api to delete package', () => {
            s = service();

            s.deleteSchemaPackage(100);
            expect(http.delete).toHaveBeenCalledWith('api/schemaPackage/100');
        });

        it('addSchemaFile should call api to add file in package', () => {
            s = service();

            s.addSchemaFile(100, 'something');
            expect(http.post).toHaveBeenCalledWith('api/schemapackage/100', 'something');
        });

        it('deleteSchemaFile should call api to delete file in package', () => {
            s = service();

            s.deleteSchemaFile(100, 1);
            expect(http.delete).toHaveBeenCalledWith('api/schemapackage/100/file/1');
        });
    });

    describe('Mapping related', () => {
        it('getMappings should call api to get mappings', () => {
            s = service();

            s.getMappings(true);
            expect(http.get).toHaveBeenCalledWith('api/schemamappings/mappings');
        });

        it('addMapping should call api to add mapping', () => {
            s = service();

            s.addMapping('mappingdetail');
            expect(http.post).toHaveBeenCalledWith('api/schemamappings', 'mappingdetail');
        });

        it('deleteMapping should call api to delete mapping', () => {
            s = service();

            s.deleteMapping(1);
            expect(http.delete).toHaveBeenCalledWith('api/schemamappings/1');
        });
    });
});