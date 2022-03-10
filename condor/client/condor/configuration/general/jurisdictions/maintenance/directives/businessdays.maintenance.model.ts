'use strict';

interface IBusinessDaysFormData {
    id: number,
    holidayDate: Date,
    dayOfWeek: string,
    holiday: string,
    countryId: string,
    displayMessage?: string,
    warningFlag?: Boolean,
}

interface IBusinessDaysGridData extends IBusinessDaysFormData {
    isAdded?: Boolean,
    isEdited?: Boolean
}

class BusinessDaysMaintenanceData {
    private _gridData: IBusinessDaysGridData;
    private _formData: IBusinessDaysFormData;

    constructor(private data: any, private dateHelper?: any) {
    }

    get GridData(): IBusinessDaysGridData {
        this._gridData = <IBusinessDaysGridData>this.data;
        this._gridData.holidayDate = this.data.holidayDate ? this.dateHelper.convertForDatePicker(this.data.holidayDate) : null,
        this._gridData.dayOfWeek = this.data.dayOfWeek;
        this._gridData.holiday = this.data.holiday;
        this._gridData.id = this.data.id,
        this._gridData.countryId = this.data.countryId
        return this._gridData;
    }

    get FormData(): IBusinessDaysFormData {
        this._formData = {
            holidayDate: this.data.holidayDate ? this.dateHelper.convertForDatePicker(this.data.holidayDate) : null,
            dayOfWeek: this.data.dayOfWeek,
            holiday: this.data.holiday,
            displayMessage: this.data.displayMessage,
            warningFlag: this.data.warningFlag,
            id: this.data.id,
            countryId: this.data.countryId
        };
        return this._formData;
    }
}
