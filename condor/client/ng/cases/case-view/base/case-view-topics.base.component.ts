import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { TopicChanges } from '../case-detail.service';
import { CaseViewViewData } from '../view-data.model';

export interface MaintenanceTopicContract extends TopicContract {
    topic: Topic;
    viewData?: TopicViewData;
    getChanges(): { [key: string]: any };
    isValid?(): boolean;
    onError(): void;
}
