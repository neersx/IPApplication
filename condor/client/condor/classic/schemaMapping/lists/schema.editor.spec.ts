describe('Inprotech.SchemaMapping.SchemaEditorController', () => {
    'use strict';

    let controller: (dependencies?: any) => SchemaEditorController,
        notificationService: any, http: any, uibModalInstance: any, fileUtils: any, fileReader: any, kendoGridBuilder: any, schemaDataService: ISchemaDataService, rootScope: ng.IRootScopeService, translate: any, q: ng.IQService;

    beforeEach(() => {
        angular.mock.module('Inprotech.SchemaMapping');
        schemaDataService = jasmine.createSpyObj('ISchemaDataService', ['addOrGetSchemaPackage', 'setPackageValidity', 'addSchemaFile', 'deleteSchemaFile', 'updateSchemaPackage']);
        fileUtils = {};
        fileReader = {};

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
            notificationService = $injector.get('notificationServiceMock');
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            translate = $injector.get('translateMock');
            http = $injector.get('httpMock');
            uibModalInstance = $injector.get('ModalInstanceMock');
        });
    });

    let c: SchemaEditorController;
    beforeEach(inject(($rootScope: ng.IRootScopeService, $q: ng.IQService, url: any) => {
        controller = function (dependencies?) {
            dependencies = dependencies ? dependencies : {};
            dependencies.options = dependencies.options ? dependencies.options : {};
            dependencies = angular.extend({
                scope: $rootScope.$new,
            }, dependencies);
            return new SchemaEditorController(dependencies.scope, notificationService, http, url, uibModalInstance, fileUtils, fileReader, schemaDataService, dependencies.options, translate, kendoGridBuilder, $q);
        };
        rootScope = $rootScope;
        q = $q;
    }));

    let baseDetails = {
        error: 'none',
        status: 'edit',
        package: {
            id: 99,
            name: 'ABCD pack'
        },
        files: ['file1', 'file2'],
        missingDependencies: ['missed1']
    };

    let returnDetails = (details?: any): void => {
        details = details || baseDetails;
        (schemaDataService.addOrGetSchemaPackage as jasmine.Spy).and.returnValue(q.when(details));
    }

    describe('initialization', () => {
        it('should call service to add schema package', () => {
            returnDetails();
            c = controller();

            expect(schemaDataService.addOrGetSchemaPackage).toHaveBeenCalledWith(-1);
        });

        it('should call service to get schema package', () => {
            returnDetails();

            c = controller({ options: { schemaId: 99 } });

            expect(schemaDataService.addOrGetSchemaPackage).toHaveBeenCalledWith(99);
        });

        it('should set details after recieving details for a schema package', () => {
            let schemaDetails = angular.extend({}, baseDetails, { error: 'Some Error!' });
            returnDetails(schemaDetails);

            c = controller({ options: { schemaId: 99 } });
            rootScope.$apply();

            expect(schemaDataService.addOrGetSchemaPackage).toHaveBeenCalledWith(99);
            expect(c.schemaId).toBe(99);
            expect(c.details.spackage.name).toBe(schemaDetails.package.name);
            expect(c.details.currentName).toBe(schemaDetails.package.name);
            expect(c.details.files).toBe(schemaDetails.files);
            expect(c.details.missingDependencies).toBe(schemaDetails.missingDependencies);
        });

        it('should set package validity', () => {
            let schemaDetails = angular.extend({}, baseDetails, { error: 'Some Error!' });

            returnDetails(schemaDetails);

            c = controller({ options: { schemaId: 99 } });
            rootScope.$apply();

            expect(c.details.spackage.isValid).toBe(false);
            expect(c.details.error).toBe(schemaDetails.error);
            expect(schemaDataService.setPackageValidity).toHaveBeenCalledWith(99, false);
        });

        it('should display package created - if new package generated', () => {
            let schemaDetails = angular.extend({}, baseDetails, { status: 'SchemaPackageCreated' });

            returnDetails(schemaDetails);
            c = controller({ options: { schemaId: 99 } });
            rootScope.$apply();

            expect(notificationService.success).toHaveBeenCalled();
        });

        it('should refresh files grid once inititialised', () => {
            let schemaDetails = baseDetails;
            returnDetails(schemaDetails);

            c = controller({ options: { schemaId: 99 } });
            c.fileGridOptions.$widget.refresh = jasmine.createSpy('refresh');
            rootScope.$apply();

            expect(c.fileGridOptions.$widget.refresh).toHaveBeenCalled();
        });
    });

    describe('file selection', () => {
        let file = { name: 'file1' };
        let validFileUpload = (): void => {
            fileUtils.isValidSchemaFileName = jasmine.createSpy('isValidSchemaFileName').and.returnValue(true);
            fileUtils.isValidXsdFileName = jasmine.createSpy('isValidXsdFileName').and.returnValue(true);
            fileUtils.isValidXsdContent = jasmine.createSpy('isValidXsdContent').and.returnValue(true);

            fileReader.readAsText = jasmine.createSpy('readAsText').and.returnValue(q.when('some content!'));
        }

        beforeEach(() => {
            returnDetails();

            c = controller();
        });

        it('should display error, if no files are selected', () => {
            c.onSelectFile();
            c.onSelectFile([]);
            expect(notificationService.alert).toHaveBeenCalledTimes(2);
            expect(schemaDataService.addSchemaFile).not.toHaveBeenCalled();
        });

        it('should display error, if more than one file is selected', () => {
            c.onSelectFile(['file1', 'file2']);

            expect(notificationService.alert).toHaveBeenCalled();
            expect(schemaDataService.addSchemaFile).not.toHaveBeenCalled();
        });

        it('should display error, if file is not valid schema file', () => {
            fileUtils.isValidSchemaFileName = jasmine.createSpy('isValidSchemaFileName').and.returnValue(false);

            c.onSelectFile([file]);

            expect(notificationService.alert).toHaveBeenCalled();
            expect(schemaDataService.addSchemaFile).not.toHaveBeenCalled();
        });

        it('should display error, if not valid Xsd', () => {
            fileUtils.isValidSchemaFileName = jasmine.createSpy('isValidSchemaFileName').and.returnValue(true);
            fileUtils.isValidXsdFileName = jasmine.createSpy('isValidXsdFileName').and.returnValue(true);
            fileUtils.isValidXsdContent = jasmine.createSpy('isValidXsdContent').and.returnValue(false);

            fileReader.readAsText = jasmine.createSpy('readAsText').and.returnValue(q.when('some content!'));

            c.onSelectFile([file]);
            rootScope.$apply();

            expect(notificationService.alert).toHaveBeenCalled();
            expect(schemaDataService.addSchemaFile).not.toHaveBeenCalled();
        });

        it('should add schema file in package by calling service', () => {
            validFileUpload();

            c.onSelectFile([file]);
            rootScope.$apply();

            expect(schemaDataService.addSchemaFile).toHaveBeenCalled();
        });

        it('should display error, if file already exists - when contents match', () => {
            validFileUpload();
            (schemaDataService.addSchemaFile as jasmine.Spy)
                .and.returnValue(q.when(
                    {
                        status: 'FileAlreadyExists',
                        contentsMatch: true
                    }));

            c.onSelectFile([file]);
            rootScope.$apply();

            expect(http.delete).toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should ask overwrite confirmation - when file already exists but contents do not match', () => {
            validFileUpload();
            (schemaDataService.addSchemaFile as jasmine.Spy)
                .and.returnValue(q.when(
                    {
                        status: 'FileAlreadyExists',
                        contentsMatch: false
                    }));

            c.onSelectFile([file]);
            rootScope.$apply();

            expect(notificationService.confirm).toHaveBeenCalled();
        });

        it('should ask overwrite confirmation - when file already exists but contents do not match', () => {
            validFileUpload();
            (notificationService.confirm as jasmine.Spy).and.returnValue(q.when({}));
            (http.put as jasmine.Spy).and.returnValue(q.when({}));
            (schemaDataService.addSchemaFile as jasmine.Spy)
                .and.returnValue(q.when(
                    {
                        status: 'FileAlreadyExists',
                        contentsMatch: false
                    }));
            c.onSelectFile([file]);
            rootScope.$apply();

            expect(http.put).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
        });

        it('should display success, if file uploaded successfully and update package status', () => {
            validFileUpload();
            (schemaDataService.addSchemaFile as jasmine.Spy)
                .and.returnValue(q.when(
                    {
                        status: 'SchemaFileCreated',
                        error: 'some error!',
                        missingDependencies: ['file99']
                    }));

            c.onSelectFile([file]);
            rootScope.$apply();

            expect(notificationService.success).toHaveBeenCalled();
            expect(c.details.spackage.isValid).toBe(false);
            expect(c.details.error).toBe('some error!');
            expect(c.details.missingDependencies).toEqual(['file99']);
        });
    });

    describe('delete file', () => {
        beforeEach(() => {
            returnDetails();

            c = controller();
            rootScope.$apply();
        });

        it('should display confirmation', () => {
            (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));
            c.onDeleteFile({ name: 'abcd' });

            expect(notificationService.confirmDelete).toHaveBeenCalled();
        });

        it('should delete the selected file after confirmation', () => {
            (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));

            c.onDeleteFile({ name: 'abcd', id: 1 });
            rootScope.$apply();

            expect(schemaDataService.deleteSchemaFile).toHaveBeenCalledWith(99, 1);
        });

        it('should refresh files grid and missing dependencies after deletion', () => {
            c.fileGridOptions.$widget.refresh = jasmine.createSpy('refresh');
            (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));
            (schemaDataService.deleteSchemaFile as jasmine.Spy).and
                .returnValue(q.when({
                    missingDependencies: ['file1']
                }));

            c.onDeleteFile({ name: 'abcd', id: 1 });
            rootScope.$apply();

            expect(c.details.missingDependencies).toEqual(['file1']);
            expect(c.fileGridOptions.$widget.refresh).toHaveBeenCalled();
        });
    });

    describe('save package', () => {
        beforeEach(() => {
            returnDetails();

            c = controller();
            rootScope.$apply();
        });

        it('should save package name, if its changed', () => {
            (schemaDataService.updateSchemaPackage as jasmine.Spy).and.returnValue(q.when({}));
            c.details.spackage.name = 'newName';

            c.save();

            expect(schemaDataService.updateSchemaPackage).toHaveBeenCalled();
        });

        // it('should display error, if error while saving the name', () => {
        //     let deferred = q.defer();
        //     (schemaDataService.updateSchemaPackage as jasmine.Spy).and.returnValue(deferred);
        //     c.details.spackage.name = 'newName';

        //     c.save();
        //     deferred.reject({ data: 'Some Error!!' });
        //     rootScope.$apply();

        //     expect(notificationService.alert).toHaveBeenCalled();
        // });

        // it('close the dialog', () => {
        //     (schemaDataService.updateSchemaPackage as jasmine.Spy).and.returnValue(q.when({}));
        //     c.details.spackage.name = 'newName';

        //     c.save();
        //     rootScope.$apply();

        //     expect(uibModalInstance.close).toHaveBeenCalled();
        // });
    });

    describe('dismissAll', () => {
        beforeEach(function () {
            returnDetails(baseDetails);
            c = controller();
            c.form = jasmine.createSpyObj('ng.IFormController', ['$setDirty']);

            rootScope.$apply();
        });

        it('should display confirmation, if unsaved changes on screen', () => {
            (notificationService.discard as jasmine.Spy).and.returnValue(q.when({}));
            c.form.$dirty = true;

            c.dismissAll();
            rootScope.$apply();

            expect(notificationService.discard).toHaveBeenCalled();
            expect(uibModalInstance.dismiss).toHaveBeenCalled();
        });

        it('should close the dialog, if no unsaved changes on screen', () => {
            c.dismissAll();

            expect(notificationService.discard).not.toHaveBeenCalled();
            expect(uibModalInstance.dismiss).toHaveBeenCalled();
        });
    });
});