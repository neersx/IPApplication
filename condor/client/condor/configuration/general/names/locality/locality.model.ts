namespace inprotech.configuration.general.names.locality {
    interface IPicklistModel {
        key?: string;
        code?: string;
        value?: string;
    }

    interface IStatePicklistModel extends IPicklistModel {
        countryCode: string;
        countryDescription: string;
    }

    export interface ILocalityEntity {
        id?: number;
        code?: string;
        name?: string;
        city?: string;
        country?: IPicklistModel;
        state?: IStatePicklistModel;
        currentState?: string;
    }

    export interface ILocalityModalOptions extends IModalOptions {
        entity?: ILocalityEntity;
    }
}