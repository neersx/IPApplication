namespace inprotech.configuration.general.ede.datamapping {
    export interface ITopicEntity {
        id?: any;
        topics?: any;
        name?: string;
        description?: string;
        event?: string;
        ignore?: boolean;
        state?: string;
    }

    export interface ITopicModalOptions extends IModalOptions {
        entity?: ITopicEntity;
        structure?: string;
        dataSource?: string;
    }
}