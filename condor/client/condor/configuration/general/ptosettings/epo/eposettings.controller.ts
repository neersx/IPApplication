'use strict';

class EpoSettingsController {
    static $inject = ['viewData', 'EpoSettingsService', 'notificationService'];

    public formData: EpoSettingModel = null;
    public initialData: EpoSettingModel = null;
    public status: any = { verified: false, isValid: false, inprogress: false };
    public form: ng.IFormController;

    constructor(viewData: any, private service: EpoSettingsService, private notificationService: any) {
        this.initialData = new EpoSettingModel(viewData.consumerKey, viewData.privateKey);
        this.setDataFromInitial();
    }

    public save = (): void => {
        this.service.save(this.formData).then((status) => {
            if (status) {
                this.notificationService.success();
                this.tested(true);
                this.saved();
            } else {
                this.tested(false);
                this.notificationService.alert({
                    errors: [{ message: 'ptosettings.epo.test-error' }]
                });
            }
        });
    }

    public discard = (): void => {
        this.status.verified = false;
        this.setDataFromInitial();
        this.form.$setPristine();
    }

    public verify = (): void => {
        this.status.inprogress = true;

        let data = this.copy(this.formData);
        if (!this.form.$dirty) {
            data.consumerKey = null;
            data.privateKey = null;
        }
        this.service.test(data).then((status) => {
            this.tested(status);
            this.status.inprogress = false;
        });
    }

    tested = (isValid: boolean): void => {
        this.status.isValid = isValid;
        this.status.verified = true;
    }

    saved = (): void => {
        this.initialData = this.copy(this.formData);
        this.form.$setPristine();
    }

    setDataFromInitial = (): void => {
        this.formData = this.copy(this.initialData);
    }

    copy = (data: EpoSettingModel): EpoSettingModel => {
        return angular.copy(data);
    }
}

angular.module('inprotech.configuration.general.ptosettings.epo')
    .controller('EpoSettingsController', EpoSettingsController);
