'use strict';

interface IPicklist {
    key?: string,
    code?: string,
    value?: string
}

interface IpropertyTypePicklist extends IPicklist {
    allowSubClass?: boolean
}

interface IClassesFormData {
    propertyTypeModel?: IpropertyTypePicklist,
    class?: string,
    subClass?: string,
    description?: string,
    notes?: string,
    effectiveDate?: Date,
    internationalClasses?: Array<IPicklist>,
    jurisdiction?: any
}

interface IClassesGridData extends IClassesFormData {
    propertyType: string,
    propertyTypeCode: string,
    intClasses?: string,
    isAdded?: Boolean,
    isEdited?: Boolean,
    allowSubClass: boolean
}

class ClassesMaintenanceData {
    private _gridData: IClassesGridData;
    private _formData: IClassesFormData;

    constructor(private data: any, private dateHelper?: any) {
    }

    get GridData(): IClassesGridData {
        this._gridData = <IClassesGridData>this.data;
        this._gridData.propertyType = angular.isDefined(this.data.propertyTypeModel) ? this.data.propertyTypeModel.value : null;
        this._gridData.propertyTypeCode = this.data.propertyTypeModel.code;
        this._gridData.allowSubClass = this.data.propertyTypeModel.allowSubClass;
        this._gridData.intClasses = angular.isDefined(this.data.internationalClasses) ? _.map(_.sortBy(this.data.internationalClasses, function (item: any) {
            return +item.code;
        }), (j: any) => j.code).join(', ') : '';
        return this._gridData;
    }

    get FormData(): IClassesFormData {
        this._formData = {
            propertyTypeModel: {
                code: this.data.propertyTypeCode,
                value: this.data.propertyType,
                allowSubClass: this.data.allowSubClass
            },
            class: this.data.class,
            subClass: this.data.subClass,
            description: this.data.description,
            notes: this.data.notes,
            effectiveDate: this.data.effectiveDate ? this.dateHelper.convertForDatePicker(this.data.effectiveDate) : null,
            internationalClasses: this.data.internationalClasses && this.data.internationalClasses.length > 0 ? this.data.internationalClasses : []
        };
        return this._formData;
    }

}