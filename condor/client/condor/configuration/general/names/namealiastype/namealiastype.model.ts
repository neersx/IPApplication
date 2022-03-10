namespace inprotech.configuration.general.names.namealiastype {
    export interface INameAliasEntity {
        id?: number;
        code?: string;
        name?: string;
        state?: string;
    }

    export interface INameAliasModalOptions extends IModalOptions {
        entity?: INameAliasEntity;
    }
}