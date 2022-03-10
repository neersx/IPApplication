import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { throttleTime } from 'rxjs/operators';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicGroup, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { DmsIntegrationService } from '../dms-integration.service';

@Component({
    selector: 'ipx-dms-data-download',
    templateUrl: './dms-data-download.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DmsDataDownloadComponent implements TopicContract, OnInit {
    dataSource: string;
    topic: Topic;
    item: any;
    hasInitialLocation = false;
    @ViewChild('dmsForm', { static: true }) form: NgForm;

    constructor(private readonly dmsService: DmsIntegrationService, private readonly cdr: ChangeDetectorRef) {
    }

    ngOnInit(): void {
        this.topic.getDataChanges = this.getChanges;
        this.dataSource = this.topic.key;
        this.item = (this.topic as any).viewData;
        this.hasInitialLocation = Boolean(this.item.location);

        this.form.statusChanges.subscribe(() => {
            this.topic.hasChanges = this.form.dirty;
            this.topic.setErrors(this.form.invalid);
            this.dmsService.raisePendingChanges(this.topic.hasChanges);
            this.dmsService.raiseHasErrors(this.form.invalid);
        });
        this.form.valueChanges.pipe(throttleTime(400)).subscribe({
            next: (v => {
                if (this.hasInitialLocation && v.enabled && !this.item.documents && !this.item.job) {
                    this.dmsService.getDataDownload(this.item.dataSourceId).subscribe({
                        next: data => {
                            this.item.documents = data.dataDownload.documents;
                            this.item.job = data.dataDownload.job;
                            this.cdr.markForCheck();
                        }
                    });
                }
            })
        });
    }

    // tslint:disable-next-line: no-empty
    sendAllToDms = (item) => {
        const status = item.job.status;
        item.job.status = 'Started';
        // tslint:disable-next-line: no-empty
        this.dmsService.sendAllToDms$(item.dataSource).subscribe(() => { }, () => {
            item.job.status = status;
            this.cdr.markForCheck();
        });
    };

    acknowledge = (item) => {
        item.job.acknowledged = true;
        this.dmsService.acknowledge$(item.job.jobExecutionId).subscribe();
    };

    private readonly getChanges = (): { [key: string]: any } => {

        return this.item;
    };
}

export class DmsDataDownloadTopic extends Topic {
    key = '';
    title = '';
    readonly component = DmsDataDownloadComponent;
    constructor(public viewData: any) {
        super();
        this.key = viewData.dataSource;
        this.title = 'dmsIntegration.lbl' + viewData.dataSource;
    }
}

export class DmsDataDownloadGroupTopic extends TopicGroup {
    readonly key = 'dataDownload';
    readonly title = 'dmsIntegration.dataDownloadFileLocation';
    info = 'dmsIntegration.dmslblDescription';
    readonly component = DmsDataDownloadComponent;
    readonly topics: Array<Topic>;
    constructor(public params: TopicParam) {
        super();

        const items = [];
        (params.viewData.items as Array<any>).forEach(item => items.push(new DmsDataDownloadTopic(item)));

        this.topics = items;
    }

    getDataChanges(): { [key: string]: any } {
        const items = {};
        items[this.key] = [];
        this.topics.forEach(t => items[this.key].push(t.getDataChanges !== undefined ? t.getDataChanges() : {}));

        return items;
    }
}