import { FormControl, NgForm, Validators } from '@angular/forms';
import { ChangeDetectorRefMock, NotificationServiceMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { ReportingConnectionStatus, ReportingServicesSetting } from '../reporting-services-integration-data';
import { ReportingIntegrationSettingsServiceMock } from '../reporting-services-integration.mock';
import { ReportingSettingsComponent } from './reporting-settings.component';

describe('ReportingSettingsComponent', () => {
    let component: ReportingSettingsComponent;
    let service: ReportingIntegrationSettingsServiceMock;
    let notificationService: NotificationServiceMock;
    let stateService: StateServiceMock;
    let cdr: ChangeDetectorRefMock;
    let translateService: TranslateServiceMock;

    beforeEach(() => {
        notificationService = new NotificationServiceMock();
        stateService = new StateServiceMock();
        cdr = new ChangeDetectorRefMock();
        translateService = new TranslateServiceMock();
        service = new ReportingIntegrationSettingsServiceMock();
        component = new ReportingSettingsComponent(service as any, notificationService as any, translateService as any, stateService as any, cdr as any);

        component.viewData = { settings: new ReportingServicesSetting() };
        component.viewData.settings.rootFolder = 'inpro';
        component.viewData.settings.reportServerBaseUrl = 'http://localhost/reportServer';
        component.form = new NgForm(null, null);
        component.form.form.addControl('rootFolder', new FormControl(null, Validators.required));
        component.form.form.addControl('baseUrl', new FormControl(null, Validators.required));
        component.form.form.addControl('maxSize', new FormControl(null, Validators.required));
        component.form.form.addControl('timeout', new FormControl(null, Validators.required));
        component.form.form.addControl('username', new FormControl(null, Validators.required));
        component.form.form.addControl('password', new FormControl(null, Validators.required));
        component.form.form.addControl('domain', new FormControl(null, Validators.required));
    });

    it('should initialise', () => {
        component.ngOnInit();
        expect(component.formData).toBe(component.viewData.settings);
    });

    it('validate save', () => {
        component.form.controls.rootFolder.setValue('inpro');
        component.form.controls.baseUrl.setValue('http://localhost/reportServer');
        component.form.controls.maxSize.setValue('20');
        component.form.controls.timeout.setValue('15');
        component.form.controls.username.setValue('username');
        component.form.controls.password.setValue('password');
        component.form.controls.domain.setValue('int');
        component.save();
        expect(service.save).toHaveBeenCalledWith(component.formData);
    });

    it('validate testConnection', () => {
        component.form.controls.rootFolder.setValue('inpro');
        component.form.controls.baseUrl.setValue('http://localhost/reportServer');
        component.form.controls.maxSize.setValue('20');
        component.form.controls.timeout.setValue('15');
        component.form.controls.username.setValue('username');
        component.form.controls.password.setValue('password');
        component.form.controls.domain.setValue('int');
        component.testConnection();
        expect(component.connectionStatus).toEqual(ReportingConnectionStatus.InProgress);
        expect(service.testConnection).toHaveBeenCalledWith(component.formData);
    });

    it('validate reload', () => {
        component.reload();
        expect(component.connectionStatus).toEqual(ReportingConnectionStatus.None);
        expect(stateService.reload).toHaveBeenCalledWith(stateService.current.name);
    });

    it('canApply should return true', () => {
        component.form.controls.rootFolder.setValue('inpro');
        component.form.controls.baseUrl.setValue('localhost/report');
        component.form.controls.maxSize.setValue('20');
        component.form.controls.timeout.setValue('15');
        component.form.controls.username.setValue('username');
        component.form.controls.password.setValue('password');
        component.form.controls.domain.setValue('int');
        component.form.controls.baseUrl.markAsDirty();
        const result = component.canApply();
        expect(result).toBeTruthy();
    });

    it('canApply should return false', () => {
        component.form.controls.rootFolder.setValue(undefined);
        component.form.controls.baseUrl.setValue('');
        component.form.controls.username.setValue('internal');
        const result = component.canApply();
        expect(result).toBeFalsy();
    });

    it('canDiscard should return true', () => {
        component.form.controls.rootFolder.setValue(undefined);
        component.form.controls.baseUrl.setValue('');
        component.form.controls.username.setValue('internal');
        component.form.controls.baseUrl.markAsDirty();
        const result = component.canDiscard();
        expect(result).toBeTruthy();
    });

    it('canDiscard should return false', () => {
        component.form.controls.baseUrl.markAsPristine();
        const result = component.canDiscard();
        expect(result).toBeFalsy();
    });

    it('canTest should return true', () => {
        component.form.controls.rootFolder.setValue('inpro');
        component.form.controls.baseUrl.setValue('www.inprotech.com/reportingserver');
        component.form.controls.maxSize.setValue('50');
        component.form.controls.timeout.setValue('20');
        component.form.controls.username.setValue('user1');
        component.form.controls.password.setValue('password1');
        component.form.controls.domain.setValue('int');
        const result = component.canTest();
        expect(result).toBeTruthy();
    });

    it('canTest should return false', () => {
        component.form.controls.baseUrl.setValue('');
        component.form.controls.username.setValue('');
        const result = component.canTest();
        expect(result).toBeFalsy();
    });

    it('setErrorOnBaseUrl - baseUr control should be valid', () => {
        component.formData.reportServerBaseUrl = 'www.inprotech.com/reportserver';
        component.setErrorOnBaseUrl(false);
        expect(component.form.controls.baseUrl.valid).toBeTruthy();
    });

    it('setErrorOnBaseUrl - baseUr control should be invalid', () => {
        component.formData.reportServerBaseUrl = '/www.inprotech.com/reportserver';
        component.setErrorOnBaseUrl(true);
        expect(component.form.controls.baseUrl.valid).toBeFalsy();
    });

    it('validateMaxMessageSize - max size control should be valid', () => {
        component.formData.messageSize = '21' as any;
        component.validateMaxMessageSize();
        expect(component.form.controls.maxSize.valid).toBeTruthy();
    });

    it('validateMaxMessageSize - max size control should be invalid', () => {
        component.formData.messageSize = 'not a number' as any;
        component.validateMaxMessageSize();
        expect(component.form.controls.maxSize.valid).toBeFalsy();
    });

    it('validateTimeout - timeout control should be valid', () => {
        component.formData.timeout = 40;
        component.validateTimeout();
        expect(component.form.controls.timeout.valid).toBeTruthy();
    });

    it('validateTimeout - timeout control should be invalid', () => {
        component.formData.timeout = 2000;
        component.validateMaxMessageSize();
        expect(component.form.controls.timeout.valid).toBeFalsy();
    });
});