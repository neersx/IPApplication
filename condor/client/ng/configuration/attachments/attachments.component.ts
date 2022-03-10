import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { map } from 'rxjs/internal/operators/map';
import { TopicContainer, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { AttachmentBrowseSettingComponent, AttachmentBrowseSettingTopic } from './attachment-browse-setting/attachment-browse-setting.component';
import { AttachmentDmsIntegrationComponent, AttachmentDmsIntegrationTopic } from './attachment-dms-integration/attachment-dms-integration.component';
import { AttachmentConfigurationService } from './attachments-configuration.service';
import { NetworkDriveMappingTopic } from './network-drive-mapping/network-drive-mapping.component';
import { AttachmentsStorageLocationsTopic } from './storage-locations/storage-locations.component';

@Component({
    selector: 'ipx-configuration-attachments',
    templateUrl: './attachments.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentsComponent extends TopicContainer implements OnInit {
    @Input() viewInitialiser: any;
    topicOptions: TopicOptions;
    isDiscardEnabled = false;
    isSaveEnabled = false;

    private storageLocations = [];
    private networkDriveMapping = [];
    private enableDms = false;
    private enableBrowseButton = false;
    private hasDmsSettings = false;
    isPageDirty = (): boolean => this.isDiscardEnabled;

    constructor(private readonly state: StateService, private readonly notificationService: NotificationService, private readonly cdr: ChangeDetectorRef, private readonly service: AttachmentConfigurationService) {
        super();
    }

    ngOnInit(): void {
        this.storageLocations = this.viewInitialiser.viewData.settings.storageLocations;
        this.networkDriveMapping = this.viewInitialiser.viewData.settings.networkDrives;
        this.enableBrowseButton = this.viewInitialiser.viewData.settings.enableBrowseButton;
        this.enableDms = this.viewInitialiser.viewData.settings.enableDms;
        this.hasDmsSettings = this.viewInitialiser.viewData.hasDmsSettings;

        this.initializeTopics();

        this.service.hasErrors$.pipe(map(this.updateUIStates)).subscribe();
        this.service.hasPendingChanges$.pipe(map(this.updateUIStates)).subscribe();
    }

    reload = () => {
        this.isDiscardEnabled = false;
        this.service.resetChangeEventState();
        this.state.reload(this.state.current.name);
    };

    save = () => {
        this.isSaveEnabled = false;
        let data = {} as any;

        this.topicOptions.topics.forEach(t => data = { ...data, ...(t.getDataChanges !== undefined ? t.getDataChanges() : {}) });

        this.saveSettings(data);
    };

    private readonly saveSettings = (data: any) => {
        this.service.save$({ ...data }).subscribe((response) => {
            if (response.invalidPath) {
                this.isSaveEnabled = false;
                this.service.resetChangeEventState();
                this.notificationService.alert({ message: 'attachmentsIntegration.invalidPathDetected' });
            } else {
                this.notificationService.success('attachmentsIntegration.attachmentsSavedSuccessfully');
                this.isDiscardEnabled = false;
                this.reload();
            }
            this.cdr.markForCheck();
        }, error => {
            this.isSaveEnabled = true;
        }, () => {
            this.service.refreshCache$().subscribe(() => {
                this.cdr.markForCheck();
            });
            this.cdr.markForCheck();
        });
    };

    private readonly initializeTopics = (): void => {
        const topics = {
            storageLocations: new AttachmentsStorageLocationsTopic({
                viewData: this.storageLocations,
                validateUrl$: this.validateUrl$
            }),
            networkDriveMapping: new NetworkDriveMappingTopic({
                viewData: this.networkDriveMapping
            }),
            browse: new AttachmentBrowseSettingTopic({
                viewData: { enableBrowseButton: this.enableBrowseButton }
            }),
            dmsIntegration: new AttachmentDmsIntegrationTopic({
                viewData: { enableDms: this.enableDms, hasDmsSettings: this.hasDmsSettings }
            })
        };
        this.topicOptions = {
            topics: [
                topics.storageLocations,
                topics.networkDriveMapping,
                topics.browse,
                topics.dmsIntegration
            ],
            actions: []
        };
    };

    private readonly validateUrl$ = (path: string) => {
        const networkDriveMappingTopic = this.topicOptions.topics.find(x => x.key === 'networkDriveMapping');
        const data = networkDriveMappingTopic.getDataChanges();

        return this.service.validateUrl$(path, data.networkDrives);
    };

    private readonly updateUIStates = () => {
        this.isDiscardEnabled = this.hasChanges();
        this.isSaveEnabled = this.isDiscardEnabled && !this.hasErrors();
    };
}