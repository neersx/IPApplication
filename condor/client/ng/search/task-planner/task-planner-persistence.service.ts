import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { QueryData, TabData } from './task-planner.data';

@Injectable()
export class TaskPlannerPersistenceService {
    changedTabSeq$ = new BehaviorSubject(null);
    private readonly _tabs = new BehaviorSubject<Array<TabData>>([]);
    private _originalTabs: Array<TabData>;

    isPicklistSearch = new BehaviorSubject<boolean>(false);
    isTabPersisted = (sequence: number): boolean => {
        return _.any(this.tabs) && this.tabs.filter(t => t.sequence === sequence)[0].isPersisted;
    };

    getTabs = (): Array<TabData> => {
        return this.tabs;
    };

    saveTabs = (tabs: Array<TabData>): void => {
        this._tabs.next(tabs);
    };

    getTabBySequence = (sequence: number) => {
        return this.tabs.filter(t => t.sequence === sequence)[0];
    };

    private get tabs(): Array<TabData> {
        return this._tabs.getValue();
    }

    private set tabs(val: Array<TabData>) {
        this._tabs.next(val);
    }

    persistInitialTabs = (queryData: Array<QueryData>): void => {
        if (!_.any(this.tabs)) {
            const persistTabs: Array<TabData> = [];
            queryData.forEach(x => {
                persistTabs.push({
                    queryKey: x.key,
                    description: x.description,
                    presentationId: x.presentationId,
                    sequence: x.tabSequence,
                    searchName: x.searchName,
                    canRevert: false
                });
            });
            this._tabs.next(persistTabs);
            this._originalTabs = persistTabs;
        }
    };

    getPersistedTabIntoQueryData = (queryData: Array<QueryData>): void => {
        if (this.tabs) {
            this.tabs.forEach(x => {
                const qd = queryData.find(tab1 => tab1.tabSequence === x.sequence);
                qd.key = x.queryKey;
                qd.description = x.description;
                qd.searchName = x.searchName;
            });
        }
    };

    saveActiveTab = (sequence: number, activeTab: TabData): void => {
        const tab = this.tabs.find(tab1 => tab1.sequence === sequence);
        const index = this.tabs.indexOf(tab);
        this.tabs[index] = activeTab;
    };

    clear = () => {
        this._tabs.next([]);
    };

    clearTabData = (sequence: number) => {
        const index = this.tabs.findIndex(tab1 => tab1.sequence === sequence);
        this.tabs[index] = this._originalTabs[index];
    };
}