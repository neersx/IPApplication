'use strict';

declare var moment: any;

interface IGroupModalOptions extends IModalOptions {
    mode: string,
    isAddAnother: Boolean,
    isGroup: Boolean,
    addItem: Function,
    type: string,
    parentId: string,
    jurisdiction: string,
    dataItem: IGroupGridData
}

interface IPicklist {
    key?: string,
    code?: string,
    value?: string
}

interface IGroupFormData {
    group?: IPicklist,
    dateCommenced?: Date,
    dateCeased?: Date,
    fullMembershipDate?: Date,
    associateMemberDate?: Date,
    isGroupDefault?: Boolean,
    preventNationalPhase?: Boolean,
    isAssociateMember?: Boolean,
    propertyTypeCollection?: Array<IPicklist>,
    jurisdiction?: any
}

interface IGroupGridData extends IGroupFormData {
    id?: string;
    name?: string;
    isAdded?: Boolean;
    isEdited?: Boolean;
    propertyTypes?: string;
    propertyTypesName?: string;
}

class GroupsMaintenanceData {
    private _gridData: IGroupGridData;
    private _formData: IGroupFormData;

    constructor(private data: any, private dateHelper?: any) {
    }

    get GridData(): IGroupGridData {
        this._gridData = <IGroupGridData>this.data;
        this._gridData.id = angular.isDefined(this.data.group) ? this.data.group.key : null;
        this._gridData.name = angular.isDefined(this.data.group) ? this.data.group.value : null;
        this._gridData.propertyTypes = angular.isDefined(this.data.propertyTypeCollection) ? _.map(_.sortBy(this.data.propertyTypeCollection, 'code'), (j: any) => j.code).join(',') : '';
        this._gridData.propertyTypesName = angular.isDefined(this.data.propertyTypeCollection) ? _.map(_.sortBy(this.data.propertyTypeCollection, 'value'), (j: any) => j.value).join(', ') : '';
        return this._gridData;
    }

    get FormData(): IGroupFormData {
        this._formData = {
            group: {
                key: this.data.id,
                code: this.data.id,
                value: this.data.name
            },
            dateCeased: this.data.dateCeased ? this.dateHelper.convertForDatePicker(this.data.dateCeased) : null,
            dateCommenced: this.data.dateCommenced ? this.dateHelper.convertForDatePicker(this.data.dateCommenced) : null,
            fullMembershipDate: this.data.fullMembershipDate ? this.dateHelper.convertForDatePicker(this.data.fullMembershipDate) : null,
            associateMemberDate: this.data.associateMemberDate ? this.dateHelper.convertForDatePicker(this.data.associateMemberDate) : null,
            isGroupDefault: this.data.isGroupDefault,
            preventNationalPhase: this.data.preventNationalPhase,
            isAssociateMember: this.data.isAssociateMember,
            propertyTypeCollection: this.data.propertyTypeCollection && this.data.propertyTypeCollection.length > 0 ? this.data.propertyTypeCollection : []
        };
        return this._formData;
    }
}