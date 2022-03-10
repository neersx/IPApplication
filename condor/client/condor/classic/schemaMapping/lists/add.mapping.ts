'use strict';

class AddMappingController {
    static $inject = ['notificationService', '$uibModalInstance', 'schemaDataService', 'options'];

    public form: ng.IFormController;
    public newMapping = {
        mappingName: null,
        schemaPackage: null,
        copyMappingFrom: null,
        rootNodes: [],
        selectedNode: null,
        error: null
    };
    public mappings = [];

    constructor(private notificationService: any, private $uibModalInstance: any,
        private schemaDataService: ISchemaDataService, private options: any) {
        this.init();
    }

    public save = (): void => {

        if (!this.form.$validate()) {
            return;
        }
        let context = this;

        this.schemaDataService.addMapping(
            {
                mappingName: this.newMapping.mappingName,
                schemaPackageId: this.newMapping.schemaPackage.id,
                copyMappingFrom: this.newMapping.copyMappingFrom ? this.newMapping.copyMappingFrom.id : null,
                rootNode: this.newMapping.selectedNode
            })
            .then(function (response) {
                if (response.status === 'NameError') {
                    context.newMapping.error = 'field.errors.notunique';
                    context.notificationService.alert({message: 'schemaMapping.usDuplicateMappingName'});
                    return;
                } else if (response.error) {
                    context.newMapping.error = 'schemaMapping.' + response.error;
                    context.notificationService.alert();
                    return;
                }
                context.$uibModalInstance.close({ id: response.mapping.id, result: 'success' });
            })
            .catch(function () {
                context.newMapping.error = 'schemaMapping.' + 'usErrorWhileMappingCreation';
            });
    }

    public dismissAll = (): void => {
        let context = this;
        if (this.form.$dirty) {
            this.notificationService.discard().then(function () {
                context.$uibModalInstance.dismiss();
            });
        } else {
            context.$uibModalInstance.dismiss();
        }
    }

    public getDocTypeText = (): string => {
        return '<!DOCTYPE ' + this.newMapping.selectedNode.name + ' SYSTEM "' + (this.newMapping.selectedNode.fileRef || '') + '">';
    }

    init = (): void => {
        this.newMapping.schemaPackage = this.options.schemaPackage;

        let context = this;
        this.schemaDataService.getRootNodesForSchemaPackage(this.newMapping.schemaPackage.id)
            .then(function (result) {
                if (result.status === 'RootNodes') {
                    context.newMapping.rootNodes = result.nodes;
                    _.each(context.newMapping.rootNodes, function (node) {
                        if (node.isDtdFile) {
                            node.fileRef = node.fileName;
                        }
                    });
                    if (context.newMapping.rootNodes.length === 1) {
                        context.newMapping.selectedNode = context.newMapping.rootNodes[0];
                        context.form.rootNode.$setDirty();
                    }
                }
            });
        this.mappings = this.schemaDataService.getMappings();
    }
}

angular.module('Inprotech.SchemaMapping')
    .controller('AddMappingController', AddMappingController);
