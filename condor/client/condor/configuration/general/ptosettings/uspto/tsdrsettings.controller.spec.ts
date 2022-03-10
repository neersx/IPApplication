describe('inprotech.configuration.general.ptosettings.uspto.TsdrSettingsController', () => {
    'use strict';

    let controller: (dependencies?: any) => TsdrSettingsController,
        notificationService: any, tsdrSettingsService: TsdrSettingsService, q: ng.IQService, rootScope: ng.IRootScopeService, form: ng.IFormController;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.ptosettings');
        tsdrSettingsService = jasmine.createSpyObj('TsdrSettingsService', ['save', 'test']);
        form = jasmine.createSpyObj('ng.IFormController', ['$setPristine']);

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks.components.notification']);
            notificationService = $injector.get('notificationServiceMock');
        });
    });

    let c: TsdrSettingsController;
    let initialData: any = {
        apiKey: 'FirstTestFile'
    };
    beforeEach(inject(($q: ng.IQService, $rootScope: ng.IRootScopeService) => {
        controller = function (dependencies?) {
            dependencies = angular.extend({
                viewData: initialData
            }, dependencies);
            return new TsdrSettingsController(dependencies.viewData, tsdrSettingsService, notificationService);
        };
        c = controller();
        c.form = form;
        q = $q;
        rootScope = $rootScope;
    }));

    it('should call service on save and return successfully', () => {
        (tsdrSettingsService.save as jasmine.Spy).and.returnValue(q.when(true));

        c.formData.apiKey = 'apiKey1';
        c.save();
        rootScope.$apply();
        expect(tsdrSettingsService.save).toHaveBeenCalledWith(c.formData);
        expect(c.status.verified).toBeTruthy();
        expect(c.status.isValid).toBeTruthy();
        expect(c.form.$setPristine).toHaveBeenCalled();
        expect(notificationService.success).toHaveBeenCalled();
    });

    it('should display error, if save fails', () => {
        (tsdrSettingsService.save as jasmine.Spy).and.returnValue(q.when(false));

        c.formData.apiKey = 'apiKey1';
        c.save();
        rootScope.$apply();
        expect(tsdrSettingsService.save).toHaveBeenCalledWith(c.formData);
        expect(c.status.verified).toBeTruthy();
        expect(c.status.isValid).toBeFalsy();
        expect(c.form.$setPristine).not.toHaveBeenCalled();
        expect(notificationService.alert).toHaveBeenCalled();
    });

    it('should discard unsaved changes', () => {
        c.formData.apiKey = 'apiKey1';

        c.discard();
        rootScope.$apply();

        expect(c.formData.apiKey).toEqual(initialData.apiKey);
        expect(c.status.verified).toBeFalsy();
        expect(c.form.$setPristine).toHaveBeenCalled();
    });

    it('should verify setting by calling the service', () => {
        (tsdrSettingsService.test as jasmine.Spy).and.returnValue(q.when(true));
        c.form.$dirty = true;

        c.verify();
        rootScope.$apply();
        expect(tsdrSettingsService.test).toHaveBeenCalledWith(c.formData);
        expect(c.status.verified).toBeTruthy();
        expect(c.status.isValid).toBeTruthy();
    });

    it('should display verification as unsuccessful, if keys are invalid', () => {
        (tsdrSettingsService.test as jasmine.Spy).and.returnValue(q.when(false));

        c.verify();
        rootScope.$apply();
        expect(c.status.isValid).toBeFalsy();
    });
});
