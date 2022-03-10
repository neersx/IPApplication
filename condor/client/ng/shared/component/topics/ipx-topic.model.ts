import { EventEmitter, TemplateRef, Type } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export enum TopicType {
    Simple = 'simple',
    SimpleRestricted = 'simpleRestrictWidth',
    Default = 'default'
}

export class TopicParam {
    viewData: any;
    topicsData?: any;
}

export type TopicsAction = {
    key: string;
    title: string;
    tooltip?: string;
};

export class Topic {
    key: string;
    title: string;
    isActive?: boolean;
    /**
     * Topic content to be rendered as Angular Component
     * @example
     * EventsComponent, ReferencesComponent etc created
     * from dev pages
     */
    component?: Type<any>;
    info?: string;
    /**
     * If Set to ipxTemplateName directive value, then
     * the content of template is rendered as tooltip
     * for inline dialog component
     * @example
     * <ng-template ipxTemplateName="templateName">
     * <p> Tooltip content </p>
     * </ng-template>
     */
    infoTemplateRef?: string | TemplateRef<any>;
    /**
     * External params such as view data is set
     * needed to initialize and render component template
     * @example
     * viewData: { isExternal: false, numberTypes: [ 'A', 'B'] }
     */
    params?: TopicParam;
    topics?: Array<Topic>;
    filters?: any;
    count?: number;
    setCount?: EventEmitter<number>;
    isGroupSection?: Boolean;
    loadedInView?: Boolean;
    loadOnDemand?: Boolean;
    loadInView?(): void;
    isInView?(): Boolean;
    isEmpty?(): Boolean;
    private readonly hasErrorSubject?: BehaviorSubject<boolean>;
    hasErrors$?: Observable<boolean>;
    hasChanges?: boolean;
    getDataChanges?(): { [key: string]: any };
    handleErrors?(response): void;
    setErrors?(isValid: boolean): void;
    getErrors?(): boolean;

    constructor() {
        this.hasErrorSubject = new BehaviorSubject<boolean>(false);
        this.hasErrors$ = this.hasErrorSubject.asObservable();

        this.setErrors = (isValid: boolean): void => {
            this.hasErrorSubject.next(isValid);
        };

        this.getErrors = (): boolean => {

            return this.hasErrorSubject.getValue();
        };
        this.setCount = new EventEmitter<number>();
    }
}

export class TopicGroup extends Topic {
    hasTopicGroupDetails: boolean;
    get hasChanges(): boolean {
        let hasChanges = false;
        this.topics.forEach(t => hasChanges = hasChanges || t.hasChanges);

        return hasChanges;
    }

    get hasErrors(): boolean {
        let hasErrors = false;
        this.topics.forEach(t => hasErrors = hasErrors || t.getErrors());

        return hasErrors;
    }

    getDataChanges(): { [key: string]: any } {
        let items = {};
        this.topics.forEach(t => items = { ...items, ...(t.getDataChanges !== undefined ? t.getDataChanges() : {}) });
        const ret = {};
        ret[this.key] = items;

        return ret;
    }
}

export class TopicContainer {
    topicOptions: TopicOptions;

    hasChanges = (): boolean => {
        let hasChanges = false;
        this.topicOptions.topics.forEach(t => hasChanges = hasChanges || t.hasChanges);

        return hasChanges;
    };

    flatten = (topics, output): void => {
        topics.forEach(topic => {
            output.push(topic);
            if (topic.topics) {
                this.flatten(topic.topics, output);
            }
        });
    };

    hasErrors = (): boolean => {
        const flattenTopics: Array<any> = [];
        this.flatten(this.topicOptions.topics, flattenTopics);
        let hasErrors = false;
        flattenTopics.forEach(t => hasErrors = hasErrors || t.hasErrorSubject.getValue());

        return hasErrors;
    };
}

export type TopicOptions = {
    topics: Array<Topic>;
    actions?: Array<TopicsAction>;
    selectedTopicKey?: string;
};

export type TopicViewData = {
    model?: any;
};