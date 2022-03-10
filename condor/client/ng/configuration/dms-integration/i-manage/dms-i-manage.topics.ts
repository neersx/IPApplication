import { EventEmitter } from '@angular/core';
import { Topic, TopicGroup, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { IManageDatabaseComponent } from './i-manage-database/i-manage-database.component';
import { IManageDataItemsComponent } from './i-manage-dataitems/i-manage-dataitems.component';
import { IManageWorkspacesComponent } from './i-manage-workspaces/i-manage-workspaces.component';

export class DmsIManageDatabaseTopic extends Topic {
    readonly key = 'databases';
    readonly title = 'dmsIntegration.iManage.databaseTitle';
    info = 'dmsIntegration.iManage.databaseInfo';
    readonly component = IManageDatabaseComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: TopicParam) {
        super();
    }
    getDataChanges = () => null;
}

export class DmsIManageWorkspacesTopic extends Topic {
    readonly key = 'workspaces';
    readonly title = 'dmsIntegration.iManage.workspaces.title';
    infoTemplateRef = 'dmsWorksiteRef';
    readonly component = IManageWorkspacesComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: TopicParam) {
        super();
    }
}

export class DmsIManageDataItemsTopic extends Topic {
    readonly key = 'dataItems';
    readonly title = 'dmsIntegration.iManage.dataItems.title';
    info = 'dmsIntegration.iManage.dataItems.dataItemInfo';
    readonly component = IManageDataItemsComponent;
    constructor(public params: TopicParam) {
        super();
    }
}

export class DmsIManageGroupTopic extends TopicGroup {
    readonly key = 'iManageSettings';
    readonly title = 'dmsIntegration.iManage.title';
    readonly component = IManageDatabaseComponent;
    readonly topics: Array<Topic>;
    constructor(public params: TopicParam) {
        super();
        this.hasTopicGroupDetails = true;
        this.topics = [
            new DmsIManageDatabaseTopic(params),
            new DmsIManageWorkspacesTopic(params),
            new DmsIManageDataItemsTopic(params)
        ];
        this.handleErrors = this.topics[0].handleErrors;
    }
}