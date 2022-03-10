'use strict';

class SchemaEditorController {
    static $inject = ['$scope', 'notificationService', '$http', 'url', '$uibModalInstance', 'fileUtils', 'fileReader', 'schemaDataService', 'options', '$translate', 'kendoGridBuilder', '$q'];

    status: string;
    error: any;
    schemaId: number;
    public details: any;
    public form: ng.IFormController;
    public fileGridOptions: any;
    public nameError: string;

    constructor(private $scope: any, private notificationService: any, private $http, private url: any, private $uibModalInstance: any,
        private fileUtils: any, private fileReader: any, private schemaDataService: ISchemaDataService,
        private options: any, private $translate: any, private kendoGridBuilder: any, private $q: any) {
        this.schemaId = this.options.schemaId || -1;
        this.fileGridOptions = this.buildGridOptionsForFileList();

        this.init();
        this.$scope.onSelectFile = this.onSelectFile;
    }

    public save = (): void => {
        let context = this;
        this.updatePackageName(this.details.spackage.name, this.details.currentName)
            .then(function (result) {
                if (result) {
                    context.notificationService.success();
                    context.$uibModalInstance.close({
                        result: 'success',
                        isValid: context.details.spackage.isValid
                    });
                }
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

    init = (): void => {
        this.status = 'loading';
        let context = this;
        this.schemaDataService.addOrGetSchemaPackage(this.schemaId).then(function (result) {
            let packageDetails = result.package;
            context.schemaId = packageDetails.id;
            context.details = context.details || {};
            context.details.spackage = packageDetails;
            context.details.currentName = context.details.spackage.name;
            context.setStatus(result.error);
            context.reset();
            if (result.status === 'SchemaPackageCreated') {
                context.details.spackage.id = packageDetails.id;
                context.notificationService.success(context.$translate.instant('schemaMapping.spLblSchemaCreatedMessage', { packageName: context.details.spackage.name }));
            }
            context.details.files = result.files || [];
            context.details.missingDependencies = result.missingDependencies || [];
            context.fileGridOptions.$read();
            context.fileGridOptions.$widget.refresh();
        }, function (err) {
            throw err;
        });
    }

    reset = (): void => {
        this.status = 'idle';
    };

    setStatus = (error): void => {
        this.error = error;
        if (error === 'none') {
            this.details.spackage.isValid = true;
            this.details.error = null;
        } else {
            this.details.spackage.isValid = false;
            this.details.error = error;
        }

        this.schemaDataService.setPackageValidity(this.schemaId, this.details.spackage.isValid);
    };

    public onSelectFile = (files?): void => {
        if (!files || files.length === 0) {
            this.notificationService.alert({ message: this.$translate.instant('schemaMapping.usErrorAtLeastOneFileShouldBeSpecified') });
            return;
        }

        if (files.length > 1) {
            this.notificationService.alert({ message: this.$translate.instant('schemaMapping.usErrorMoreThanOneFileSelected') });
            return;
        }

        let file = files[0];

        let context = this;

        if (!this.fileUtils.isValidSchemaFileName(file.name)) {
            context.notificationService.alert({ message: this.$translate.instant('schemaMapping.usErrorInvalidFileType') });
            return;
        }

        this.fileReader.readAsText(file).then(function (content) {
            if (context.fileUtils.isValidXsdFileName(file.name) && !context.fileUtils.isValidXsdContent(content)) {
                context.notificationService.alert({ message: context.$translate.instant('schemaMapping.usErrorInvalidFileContent') });
                return;
            }

            context.status = 'uploading';
            context.schemaDataService.addSchemaFile(context.schemaId, {
                fileName: file.name,
                content: content
            }).then(function (response) {
                switch (response.status) {
                    case 'FileAlreadyExists':
                        if (response.contentsMatch) {
                            context.$http.delete(context.url.api('storage/' + response.uploadedFileId));
                            context.showFileExistsWarning(file.name);
                            context.reset();
                        } else {
                            context.details.missingDependencies = response.missingDependencies;
                            context.overWriteConfirm(response.existingFileId, response.uploadedFileId, file.name)
                        }
                        return;
                    case 'SchemaFileCreated':
                        context.addFile(response.schemaFile);
                        context.details.missingDependencies = response.missingDependencies;
                        context.setStatus(response.error);
                        context.showFileUploaded(file.name);
                        context.reset();
                        break;
                }
            }).catch(function () {
                context.notificationService.error(context.$translate('schemaMapping.usErrorInvalidFileContent'));
            });
        });
    };

    public onDeleteFile = (file): void => {
        let context = this;
        this.notificationService.confirmDelete({ message: 'modal.confirmDelete.message' }).then(function () {
            context.schemaDataService.deleteSchemaFile(context.schemaId, file.id)
                .then(function (result) {
                    context.details.missingDependencies = result.missingDependencies;
                    context.setStatus(result.error);
                    let f = _.findWhere(context.details.files, { id: file.id });
                    context.details.files.splice(_.indexOf(context.details.files, f), 1);
                    context.refreshFileGrid();
                    context.reset();
                });
        }, function () {
            context.reset();
        });
    };

    overWriteConfirm = (existingFileId: number, uploadedFileId: number, name: string): void => {
        let context = this;
        this.notificationService.confirm({
            message: 'schemaMapping.usLblOverwriteFileMessage'
        }).then(function () {
            context.$http.put(context.url.api('storage/' + existingFileId + '?withFileId=' + uploadedFileId))
                .then(function () {
                    context.showFileUploaded(name);
                    context.reset();
                    context.init();
                });
        }, function () {
            context.$http.delete(context.url.api('storage/' + uploadedFileId)).then(function () {
                context.reset();
            });
        });
    };

    updatePackageName = (newVal, oldVal): Promise<Boolean> => {
        let deferred = this.$q.defer();
        if (newVal === '') {
            this.notificationService.alert({ message: 'schemaMapping.spMandatoryNameError' });
            this.nameError = 'field.errors.required';
            this.details.spackage.name = oldVal;
            return deferred.resolve(false);
        }

        if (newVal === oldVal) {
            return deferred.resolve(true);
        }

        let context = this;
        return this.schemaDataService.updateSchemaPackage(this.schemaId, newVal)
            .then(function () {
                return true;
            }, function (response) {
                if (response.data === 'DUPLICATE_NAME') {
                    context.notificationService.alert({ message: 'schemaMapping.spDuplicateNameError' });
                    context.nameError = 'field.errors.notunique';
                } else {
                    context.notificationService.alert({ message: 'schemaMapping.response' });
                }
                return false;
            });
    };

    showFileExistsWarning = (fileName): void => {
        this.notificationService.alert({
            title: this.$translate.instant('modal.unableToComplete'),
            message: this.$translate.instant('schemaMapping.spLblDuplicateSchemaMessage', { filename: fileName })
        })
    };

    showFileUploaded = (fileName): void => {
        this.notificationService.success(this.$translate.instant('schemaMapping.usLblFileUploaded', { filename: fileName }));
    };

    addFile = (file): void => {
        this.details.files.push(file);
        this.refreshFileGrid();
    }

    refreshFileGrid = (): void => {
        this.fileGridOptions.$read();
        this.fileGridOptions.$widget.refresh();
    }

    public buildGridOptionsForFileList = (): any => {
        let context = this;

        return this.kendoGridBuilder.buildOptions(this.$scope, {
            id: 'schemas',
            scrollable: false,
            reorderable: false,
            navigatable: true,
            serverFiltering: false,
            autoBind: true,
            read: function () {
                return context.details ? context.details.files : null;
            },
            columns: this.getColumns()
        });
    }

    private getColumns = (): any => {
        return [{
            title: 'schemaMapping.spLblFileName',
            sortable: true,
            field: 'name',
            template: '{{dataItem.name}}'
        }, {
            title: 'schemaMapping.usLblLastModified',
            field: 'updatedOn',
            sortable: true,
            template: '{{dataItem.updatedOn | localeDate}}'
        },
        {
            sortable: false,
            template: function (dataItem) {
                let html = '<div class="pull-right">';
                html += '<button id="btnDeleteFile_{{dataItem.id}}" ng-click="vm.onDeleteFile(dataItem); $event.stopPropagation();" class="btn btn-discard schemaMapping-button" translate="schemaMapping.usBtnDelete" />';
                html += '</div>'
                return html;
            }
        }];
    }
}

angular.module('Inprotech.SchemaMapping')
    .controller('SchemaEditorController', SchemaEditorController);
