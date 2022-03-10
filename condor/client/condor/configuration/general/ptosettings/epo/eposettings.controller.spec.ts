describe('inprotech.configuration.general.ptosettings.epo.EpoSettingsController', () => {
    'use strict';

    let controller: (dependencies?: any) => EpoSettingsController,
        notificationService: any, epoSettingsService: EpoSettingsService, q: ng.IQService, rootScope: ng.IRootScopeService, form: ng.IFormController;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.ptosettings');
        epoSettingsService = jasmine.createSpyObj('EpoSettingsService', ['save', 'test']);
        form = jasmine.createSpyObj('ng.IFormController', ['$setPristine']);

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks.components.notification']);
            notificationService = $injector.get('notificationServiceMock');
        });
    });

    let c: EpoSettingsController;
    let initialData: any = {
        consumerKey: 'TypeScript',
        privateKey: 'FirstTestFile'
    };
    beforeEach(inject(($q: ng.IQService, $rootScope: ng.IRootScopeService) => {
        controller = function (dependencies?) {
            dependencies = angular.extend({
                viewData: initialData
            }, dependencies);
            return new EpoSettingsController(dependencies.viewData, epoSettingsService, notificationService);
        };
        c = controller();
        c.form = form;
        q = $q;
        rootScope = $rootScope;
    }));

    it('should call service on save and return successfully', () => {
        (epoSettingsService.save as jasmine.Spy).and.returnValue(q.when(true));

        c.formData.consumerKey = 'consumerKey1';
        c.formData.privateKey = 'privateKey1';

        c.save();
        rootScope.$apply();
        expect(epoSettingsService.save).toHaveBeenCalledWith(c.formData);
        expect(c.status.verified).toBeTruthy();
        expect(c.status.isValid).toBeTruthy();
        expect(c.form.$setPristine).toHaveBeenCalled();
        expect(notificationService.success).toHaveBeenCalled();
    });

    it('should display error, if save fails', () => {
        (epoSettingsService.save as jasmine.Spy).and.returnValue(q.when(false));

        c.formData.consumerKey = 'consumerKey1';
        c.formData.privateKey = 'privateKey1';

        c.save();
        rootScope.$apply();
        expect(epoSettingsService.save).toHaveBeenCalledWith(c.formData);
        expect(c.status.verified).toBeTruthy();
        expect(c.status.isValid).toBeFalsy();
        expect(c.form.$setPristine).not.toHaveBeenCalled();
        expect(notificationService.alert).toHaveBeenCalled();
    });

    it('should discard unsaved changes', () => {
        c.formData.consumerKey = 'consumerKey1';
        c.formData.privateKey = 'privateKey1';

        c.discard();
        rootScope.$apply();

        expect(c.formData.consumerKey).toEqual(initialData.consumerKey);
        expect(c.formData.privateKey).toEqual(initialData.privateKey);
        expect(c.status.verified).toBeFalsy();
        expect(c.form.$setPristine).toHaveBeenCalled();
    });

    it('should verify setting by calling the service', () => {
        (epoSettingsService.test as jasmine.Spy).and.returnValue(q.when(true));
        c.form.$dirty = true;

        c.verify();
        rootScope.$apply();
        expect(epoSettingsService.test).toHaveBeenCalledWith(c.formData);
        expect(c.status.verified).toBeTruthy();
        expect(c.status.isValid).toBeTruthy();
    });

    it('should display verification as unsuccessful, if keys are invalid', () => {
        (epoSettingsService.test as jasmine.Spy).and.returnValue(q.when(false));

        c.verify();
        rootScope.$apply();
        expect(c.status.isValid).toBeFalsy();
    });
});
