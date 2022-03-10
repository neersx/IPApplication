namespace inprotech.configuration.search {
    'use strict';

export class ConfigurationItemModel {
    rowKey: string;
    id: number | null;
    ids: number[];
    groupId: number | null;
    name: string;
    description: string;
    tags: Tags[];
    state: string;
    saved: boolean;
}

export class Tags {
    id: number;
    key: number;
    tagName: string
}

export interface IConfigurationItemModelOptions extends IModalOptions {
        entity?: ConfigurationItemModel;
    }
}