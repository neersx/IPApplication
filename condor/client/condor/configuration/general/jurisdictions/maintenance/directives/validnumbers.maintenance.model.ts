'use strict';

interface IPicklist {
    key?: string,
    code?: string,
    value?: string
}

interface IValidNumbersFormData {
    propertyType?: IPicklist,
    numberType?: IPicklist,
    additionalValidation?: IPicklist,
    subType?: IPicklist,
    caseType?: IPicklist,
    caseCategory?: IPicklist,
    pattern?: string,
    displayMessage?: string,
    warningFlag?: Boolean,
    validFrom?: Date,
    jurisdiction?: any,
    testPatternNumber?: any
}

interface IValidNumbersGridData extends IValidNumbersFormData {
    propertyTypeName?: string,
    propertyTypeCode?: string,
    subTypeName?: string,
    subTypeCode?: string,
    caseTypeName?: string,
    caseTypeCode?: string,
    caseCategoryName?: string,
    caseCategoryCode?: string,
    numberTypeName?: string,
    numberTypeCode?: string,
    additionalValidationName?: string,
    additionalValidationId?: number,
    isAdded?: Boolean,
    isEdited?: Boolean
}

class ValidNumbersMaintenanceData {
    private _gridData: IValidNumbersGridData;
    private _formData: IValidNumbersFormData;

    constructor(private data: any, private dateHelper?: any) {
    }

    get GridData(): IValidNumbersGridData {
        this._gridData = <IValidNumbersGridData>this.data;
        this._gridData.propertyTypeName = this.data.propertyType ? this.data.propertyType.value : null;
        this._gridData.propertyTypeCode = this.data.propertyType.code;
        this._gridData.subTypeName = this.data.subType ? this.data.subType.value : null;
        this._gridData.subTypeCode = this.data.subType ? this.data.subType.code : null;
        this._gridData.caseTypeName = this.data.caseType ? this.data.caseType.value : null;
        this._gridData.caseTypeCode = this.data.caseType ? this.data.caseType.code : null;
        this._gridData.caseCategoryName = this.data.caseCategory ? this.data.caseCategory.value : null;
        this._gridData.caseCategoryCode = this.data.caseCategory ? this.data.caseCategory.code : null;
        this._gridData.numberTypeName = this.data.numberType ? this.data.numberType.value : null;
        this._gridData.numberTypeCode = this.data.numberType.code;
        this._gridData.additionalValidationName = this.data.additionalValidation ? this.data.additionalValidation.value : null;
        this._gridData.additionalValidationId = this.data.additionalValidation ? this.data.additionalValidation.key : null;
        return this._gridData;
    }

    get FormData(): IValidNumbersFormData {
        this._formData = {
            propertyType: {
                code: this.data.propertyTypeCode,
                value: this.data.propertyTypeName
            },
            caseType: {
                code: this.data.caseTypeCode,
                value: this.data.caseTypeName,
                key: this.data.caseTypeCode
            },
            subType: {
                code: this.data.subTypeCode,
                value: this.data.subTypeName
            },
            caseCategory: {
                code: this.data.caseCategoryCode,
                value: this.data.caseCategoryName
            },
            numberType: {
                code: this.data.numberTypeCode,
                value: this.data.numberTypeName
            },
            additionalValidation: {
                key: this.data.additionalValidationId,
                code: this.data.additionalValidationId,
                value: this.data.additionalValidationName
            },
            pattern: this.data.pattern,
            displayMessage: this.data.displayMessage,
            warningFlag: this.data.warningFlag,
            validFrom: this.data.validFrom ? this.dateHelper.convertForDatePicker(this.data.validFrom) : null
        };
        return this._formData;
    }

}