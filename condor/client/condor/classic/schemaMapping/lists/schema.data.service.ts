'use strict';

interface ISchemaDataService {
    getSchemas(): any[];

    addOrGetSchemaPackage(schemaId: number): any;
    getRootNodesForSchemaPackage(schemaId: number): any;
    updateSchemaPackage(schemaId: number, name: string): any; // will update mappings
    deleteSchemaPackage(schemaId: number): any; // will update mappings

    addSchemaFile(schemaId: number, content: any): any;
    deleteSchemaFile(schemaId: number, fileId: number): any;
    setPackageValidity(packageId, isValid): void; // will update mappings

    getMappings(refresh?: boolean): any[];
    addMapping(mappingDetails: any): any;
    deleteMapping(mappingId: number): any;

    getMappingNamesFor(schemaId: number): string[];
    mappingReloaded(): void;
    mappingsModified(): Boolean;
}

class SchemaDataService implements ISchemaDataService {
    static $inject = ['$http', 'url'];

    mappings: any[];
    schemas: any[];

    public mappingsNeedsReload: Boolean = false;

    constructor(private $http, private url: any) {
    }

    addOrGetSchemaPackage = (schemaId: number): any => {
        return this.$http.get(this.url.api('schemapackage/' + schemaId + '/details'))
            .then(function (response) {
                return response.data;
            });
    }

    getRootNodesForSchemaPackage = (schemaId: number): any => {
        return this.$http.get(this.url.api('schemapackage/' + schemaId + '/roots'))
            .then(function (response) {
                return response.data;
            });
    }

    updateSchemaPackage = (schemaId: number, name: string): any => {
        return this.$http.put(this.url.api('schemapackage/' + schemaId + '/name'), {
            name: name
        });
    }

    deleteSchemaPackage = (schemaId: number): any => {
        let context = this;

        return this.$http.delete(this.url.api('schemaPackage/' + schemaId)).then(function () {
            context.mappings = _.chain(context.mappings)
                .difference(_.where(context.mappings, { schemaPackageId: schemaId }))
                .value();

            context.mappingsNeedsReload = true;
        });
    }

    addSchemaFile = (schemaId: number, content: any): any => {
        return this.$http.post(this.url.api('schemapackage/' + schemaId), content)
            .then(function (response) {
                return response.data;
            });
    }

    deleteSchemaFile = (schemaId: number, fileId: number): any => {
        return this.$http.delete(this.url.api('schemapackage/' + schemaId + '/file/' + fileId))
            .then(function (response) {
                return response.data;
            })
    }

    getMappings = (refresh = false): any[] => {
        let context = this;

        if (!refresh && this.mappings) {
            return this.mappings;
        }
        return this.$http.get(this.url.api('schemamappings/mappings'))
            .then(function (response) {
                context.mappings = response.data
                return context.mappings;
            });
    }

    addMapping = (mappingDetails: any): any => {
        return this.$http.post(this.url.api('schemamappings'), mappingDetails)
            .then(function (response) {
                return response.data;
            });
    }

    deleteMapping = (mappingId): any => {
        let context = this;

        return this.$http.delete(this.url.api('schemamappings/' + mappingId)).then(function () {
            context.mappings = _.chain(context.mappings)
                .difference(_.where(context.mappings, { id: mappingId }))
                .value();

            context.mappingsNeedsReload = true;
        });
    }
    getSchemas = (): any[] => {
        let context = this;

        return this.$http.get(this.url.api('schemapackage/list'))
            .then(function (response) {
                context.schemas = response.data;
                return context.schemas;
            });
    }

    setPackageValidity = (packageId: any, isValid: any): void => {
        let schema = _.findWhere(this.schemas, { id: packageId });
        if (schema) {
            schema.isValid = isValid;
        }

        _.chain(this.mappings)
            .where({ schemaPackageId: packageId })
            .each(function (m) {
                m.isValid = isValid;
            });

        this.mappingsNeedsReload = true;
    }

    getMappingNamesFor = (schemaId: number): string[] => {
        return _.pluck(_.where(this.mappings, {
            schemaPackageId: schemaId
        }), 'name');
    }

    mappingsModified = (): Boolean => {
        return this.mappingsNeedsReload;
    }

    mappingReloaded = (): void => {
        this.mappingsNeedsReload = false;
    }
}
angular.module('Inprotech.SchemaMapping')
    .service('schemaDataService', SchemaDataService);
