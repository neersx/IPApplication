'use strict';

class BusinessdaysMaintenanceController {
    static $inject = ['$scope', '$uibModalInstance', 'options', 'maintenanceModalService', 'jurisdictionBusinessDaysService', 'dateHelper', 'notificationService', '$translate', 'hotkeys', 'modalService'];

    public form: ng.IFormController;
    public formData: IBusinessDaysFormData;
    public isAddAnother: Boolean;
    public maintModalService;
    public isEdit: boolean;
    public title: string;
    public entity: any;
    public hasNevigated: boolean;

    constructor(private $scope: ng.IScope, private $uibModalInstance, private options: any, private maintenanceModalService, private jurisdictionBusinessDaysService, private dateHelper, private notificationService, private $translate, private hotkeys, private modalService) {
        this.isAddAnother = this.options.isAddAnother;
        this.isEdit = this.options.mode === 'edit';
        this.entity = {
            state: this.options.entityState
        };
        this.formData = {} as IBusinessDaysFormData;

        if (this.isEdit) {
             this.getHolidayById(this.options.dataItem);
        }

        this.maintModalService = this.maintenanceModalService(this.$scope, this.$uibModalInstance, this.options.addItem);
        this.title = this.isEdit ? '.editTitle' : '.addTitle';
        this.initShortcuts();
      }

    dismiss = (): void => {
        this.$uibModalInstance.dismiss();
    }

    onDateBlur = (field, newVal) => {
        this.getDayOfWeek(newVal);
    }

    getDayOfWeek = (date: Date) => {
        let formData = this.formData;
        this.jurisdictionBusinessDaysService.getDayOfWeek(date).then((data) => {
            formData.dayOfWeek = data;
        });
    }

    getHolidayById = (selectedItem: number): void => {
        this.jurisdictionBusinessDaysService.getCountryHolidayById(this.options.parentId, selectedItem)
        .then((response: any) => {
            if (response) {
                response.holidayDate = this.dateHelper.convertForDatePicker(response.holidayDate);
                this.formData = response;
            }
        });
    }

    apply = (keepOpen: boolean) => {
        if (!this.form.$validate()) {
            return false;
        }
        let data = this.convertToSaveModel(this.formData);
        this.jurisdictionBusinessDaysService.isDuplicated(data)
        .then((response: any) => {
            if (response.data) {
                this.notificationService.alert({
                    message: this.$translate.instant('jurisdictions.maintenance.businessDays.duplicate'),
                    title: this.$translate.instant('modal.unableToComplete')
                });
                return false;
            }
            this.jurisdictionBusinessDaysService.saveCountryHolidays(data).then(() => {
                this.form.$setPristine();
                this.notificationService.success(this.$translate.instant('jurisdictions.maintenance.businessDays.changesSavedSuccessfully'));
                if (this.options.refreshGrid !== null) {
                    this.options.refreshGrid();
                }
                this.maintModalService.applyChanges(null, this.options, this.isEdit, this.isAddAnother, keepOpen);
                return true;
            });
        });
    }

    convertToSaveModel = (dataItem: IBusinessDaysFormData): any => {
        let model = {
            id: dataItem.id,
            countryId: this.options.parentId,
            holiday: dataItem.holiday,
            holidayDate: dataItem.holidayDate
        };
        return model;
    }

    isApplyEnabled = (): Boolean => {
        return !this.form.$pristine && !this.form.$invalid;
    }

    hasUnsavedChanges = (): Boolean => {
        return this.form.$dirty;
    }

    disable = () => {
        return !(this.form.$dirty && this.form.$valid);
    }


    onNavigate = (): boolean => {
        if (this.form.$pristine) {
            return true;
        } else {
            this.notificationService.discard().then(() => {
                this.form.$setPristine();
                this.navigateToNextRecord();
                return true;
            });
            return false;
        }
    }

    navigateToNextRecord = (): void => {
        let allItems = this.options.allItems;
        let currentItem = this.options.dataItem;
        let currentIndex = _.indexOf(allItems, currentItem);

        if (currentIndex < (allItems.length - 1)) {
            let newItem = this.options.allItems[currentIndex + 1];
            this.$scope.$emit('modalChangeView', {
                dataItem: newItem
            });
        }
    }


    initShortcuts = () => {
        this.hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: () => {
                if (!this.disable() && this.modalService.canOpen('BusinessdaysMaintenance')) {
                    this.apply(false);
                }
            }
        });
        this.hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: () => {
                if (this.hasUnsavedChanges()) {
                    return this.notificationService.discard().then(() => {
                        this.dismiss();
                    });
                } else {
                    this.dismiss();
                }
            }
        });
    }

}

angular.module('inprotech.configuration.general.jurisdictions')
    .controller('BusinessdaysMaintenanceController', BusinessdaysMaintenanceController);
