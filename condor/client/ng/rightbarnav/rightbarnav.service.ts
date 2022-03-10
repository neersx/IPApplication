import { Injectable, Type } from '@angular/core';
import * as angular from 'angular';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { KotModel } from './keepontopnotes/keep-on-top-notes-models';

export interface IContextNavService {
    registercontextuals(contextualItems: IQuickNavList | null | undefined): void;
    onAddContextual(cb: (contextualItems: IQuickNavList | null | undefined) => void): void;
}

export interface IQuickNavService extends IContextNavService {
    registerDefault(id: string, model: QuickNavModel): QuickNavModel;
    getDefault(): IQuickNavList;
    onAdd(cb: (id: string, navModel: QuickNavModel) => void): void;
}

export class QuickNavModelOptions {
    resolve?: any;
    constructor(public id?: string, public icon?: string, public title?: string,
        public tooltip?: string, public shortcutCombo?: string, public click?: () => void, public callBack?: () => void) {
    }
}

export class QuickNavModel {
    constructor(public component: Type<any>, public options: QuickNavModelOptions) { }
}

export interface IQuickNavList {
    [id: string]: QuickNavModel;
}

@Injectable()
export class RightBarNavService implements IQuickNavService {

    private readonly defaults: IQuickNavList = {};
    private contextuals: IQuickNavList = {};
    private readonly callbacks: Array<(id: string, navModel: QuickNavModel) => void> = [];
    private readonly callbacksForContext: Array<(context: IQuickNavList) => void> = [];
    private callBackForKot: (kotNotes: Array<KotModel> | null | undefined) => void;
    onCloseRightBarNav$ = new BehaviorSubject(false);

    registerDefault = (id: string, model: QuickNavModel): QuickNavModel => {
        if (angular.isUndefined(this.defaults[id])) {
            const prefix = 'quicknav.' + id + '.';
            this.defaults[id] = new QuickNavModel(
                model.component,
                angular.extend({}, {
                    id,
                    icon: prefix + 'icon',
                    title: prefix + 'title',
                    tooltip: prefix + 'tooltip'
                }, model.options));
            this.notifyNewNavComponent(id, this.defaults[id]);
        }

        return this.defaults[id];
    };

    getDefault = (): IQuickNavList => {
        return this.defaults;
    };

    onAdd = (cb: (id: string, navModel: QuickNavModel) => void): void => {
        this.callbacks.push(cb);
    };

    onAddContextual = (cb: (contextualItems: IQuickNavList | null | undefined) => void): void => {
        this.callbacksForContext.push(cb);
    };

    registercontextuals = (contextualItems: IQuickNavList | null | undefined): void => {
        if (!this.hasKeys(this.contextuals) && !this.hasKeys(contextualItems)) {
            return;
        }
        this.contextuals = contextualItems;
        _.each(this.callbacksForContext, (cb) => {
            cb(this.contextuals);
        });
    };

    onAddKot = (cb: (kotNotes: Array<KotModel> | null | undefined) => void) => {
        this.callBackForKot = cb;
    };

    registerKot = (kotNotes: Array<KotModel> | null | undefined): void => {
        this.callBackForKot(kotNotes);
    };

    notifyNewNavComponent = (id: string, newItem: QuickNavModel) => {
        _.each(this.callbacks, (cb) => {
            cb(id, newItem);
        });
    };

    private readonly hasKeys = (obj: any): boolean => {
        return obj && Object.keys(obj).length > 0;
    };
}