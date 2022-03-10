import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Observable, of } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { TopicContainer, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { DmsDataDownloadGroupTopic } from './data-download/dms-data-download.component';
import { ConnectionResponseModel, DmsIntegrationService } from './dms-integration.service';
import { WorkspaceType } from './dms-models';
import { DmsIManageGroupTopic } from './i-manage/dms-i-manage.topics';
import { IManageCredentialsInputComponent } from './i-manage/i-manage-database/i-manage-database/i-manage-credentials-input/i-manage-credentials-input.component';
import { IManageTestWorkspaceComponent } from './i-manage/i-manage-test-workspace/i-manage-test-workspace.component';

@Component({
    selector: 'ipx-dms-integration',
    templateUrl: './dms-integration.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DmsIntegrationComponent extends TopicContainer implements OnInit {
    @Input() viewInitialiser: any;
    isSaveEnabled = false;
    isDiscardEnabled = false;
    topicOptions: TopicOptions;
    httpStatus = {
        BadRequest: 400
    };
    items: any;
    imanageSettings: any;
    defaultSiteUrls: string;
    testingConnection = false;
    isImanageEnabled = false;

    disableTestWorkspace = false;
    workspaceType = WorkspaceType;

    constructor(private readonly service: DmsIntegrationService,
        private readonly notificationService: NotificationService,
        private readonly state: StateService,
        private readonly cdr: ChangeDetectorRef,
        private readonly translate: TranslateService,
        readonly modalService: IpxModalService,
        private readonly ipxNotificationService: IpxNotificationService) {
        super();
    }

    ngOnInit(): void {
        this.items = this.viewInitialiser.viewData.dataDownload;
        this.imanageSettings = this.viewInitialiser.viewData.iManage;
        this.defaultSiteUrls = this.viewInitialiser.viewData.defaultSiteUrls;
        this.isImanageEnabled = !this.viewInitialiser.viewData.iManage.disabled;
        this.initializeTopics();

        this.service.hasErrors$.pipe(map(this.updateUIStates)).subscribe();
        this.service.hasPendingChanges$.pipe(map(this.updateUIStates)).subscribe();
    }

    getCredentials = (databases: Array<any>): Observable<any> => {
        const showCredentials = this.service.getRequiresCredentials(databases);
        if ((!showCredentials.showUsername && !showCredentials.showPassword) || !this.isImanageEnabled) {
            return of({});
        }

        const modal = this.modalService.openModal(IManageCredentialsInputComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                databases
            }
        });

        return modal.content.onClose$;
    };

    testConnections$ = (username: string, password: string, databases: Array<any>): Promise<Array<ConnectionResponseModel>> => {
        if (!this.isImanageEnabled) {
            return Promise.resolve(null);
        }

        return this.service.testConnections$(username, password, databases);
    };

    isEnabledDirty = false;
    enabledChanged = () => {
        this.isEnabledDirty = true;
    };

    save = () => {
        this.isSaveEnabled = false;
        let data = {} as any;

        this.topicOptions.topics.forEach(t => data = { ...data, ...(t.getDataChanges !== undefined ? t.getDataChanges() : {}) });
        const iManageTopic = this.topicOptions.topics.find(x => x.key === 'iManageSettings');
        data.iManageSettings.disabled = !this.isImanageEnabled;
        data.iManageSettings.hasDatabaseChanges = this.service.hasPendingDatabaseChanges$.getValue();

        if (iManageTopic.hasChanges && !this.isImanageEnabled) {
            const notificationRef = this.ipxNotificationService.openConfirmationModal('dmsIntegration.iManage.confirmSave.title', 'dmsIntegration.iManage.confirmSave.message', 'dmsIntegration.iManage.confirmSave.confirmText', 'dmsIntegration.iManage.confirmSave.cancelText');
            notificationRef.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.isImanageEnabled = true;
                    data.iManageSettings.disabled = !this.isImanageEnabled;
                    this.finalSave(data, true);
                });
            notificationRef.content.cancelled$.pipe(
                take(1))
                .subscribe(() => {
                    this.finalSave(data, true);
                });
        } else {
            this.finalSave(data, iManageTopic.hasChanges);
        }
    };

    finalSave(data: any, dmsSettingChanged: boolean): any {
        const databases = data.iManageSettings.Databases;

        if (dmsSettingChanged && (databases == null || (databases as Array<any>).length === 0)) {
            this.notificationService.alert({
                message: this.translate.instant('dmsIntegration.iManage.emptyDatabases')
            });

            return;
        }

        if (data.iManageSettings.hasDatabaseChanges) {
            this.getCredentials(databases).subscribe((credentials) => {
                if (credentials) {
                    this.testingConnection = true;
                    this.cdr.markForCheck();
                    this.testConnections$(credentials.username, credentials.password, databases).then(results => {
                        this.testingConnection = false;
                        this.cdr.markForCheck();
                        if (results && results.filter(result => !result.success).length > 0) {
                            this.notificationService.alert({
                                message: this.translate.instant('dmsIntegration.iManage.unsuccessfulConnection')
                            });
                            this.topicOptions.topics.forEach(t => {
                                if (t.handleErrors !== undefined) {
                                    t.handleErrors(results);
                                }
                                if (t.topics) {
                                    t.topics.forEach(subTopic => {
                                        if (subTopic.handleErrors !== undefined) {
                                            subTopic.handleErrors(results);
                                        }
                                    });
                                }
                            });

                            this.isSaveEnabled = true;
                            this.cdr.markForCheck();
                        } else {
                            this.saveSettings(data, credentials);
                        }
                    });
                } else {
                    this.isSaveEnabled = true;
                    this.cdr.markForCheck();
                }
            });
        } else {
            this.saveSettings(data, {});
        }
    }

    openTestWorkspaceModal = (workspaceType: WorkspaceType) => {
        let data = {};
        this.topicOptions.topics.forEach(t => data = { ...data, ...(t.getDataChanges !== undefined ? t.getDataChanges() : {}) });
        const iManageSettingData = { iManageSettings: {} };
        iManageSettingData.iManageSettings = (data as any).iManageSettings;
        this.modalService.openModal(IManageTestWorkspaceComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                iManageSettingData,
                workspaceType
            }
        });
    };

    reload = () => {
        this.isDiscardEnabled = false;
        this.state.reload(this.state.current.name);
    };

    isPageDirty = (): boolean => this.isDiscardEnabled;

    private readonly saveSettings = (data: any, credentials: any) => {
        this.service.save$({ ...data, ...credentials }).subscribe(resp => {
            if (resp && resp.result && resp.result.error) {
                this.isSaveEnabled = true;
                this.notificationService.alert({
                    message: this.translate.instant('dmsIntegration.lbl' + resp.result.error)
                });
            } else if (resp.connectionResults) {
                this.isSaveEnabled = true;
                this.notificationService.alert({
                    message: this.translate.instant('dmsIntegration.iManage.unsuccessfulConnection')
                });
            } else {
                this.service.hasPendingDatabaseChanges$.next(false);
                this.notificationService.success();
                this.isDiscardEnabled = false;
                this.reload();
            }
        }, error => {
            this.isSaveEnabled = true;
        }, () => {
            this.cdr.markForCheck();
        });
    };

    private readonly initializeTopics = (): void => {
        const topics = {
            imanage: new DmsIManageGroupTopic({
                viewData: { imanageSettings: this.imanageSettings, defaultSiteUrls: this.defaultSiteUrls },
                topicsData: this.topicOptions ? this.topicOptions.topics : []
            }),
            dataDownload: new DmsDataDownloadGroupTopic({
                viewData: { items: this.items }
            })
        };
        this.topicOptions = {
            topics: [
                topics.imanage,
                topics.dataDownload
            ],
            actions: []
        };
    };

    private readonly updateUIStates = () => {
        this.isDiscardEnabled = this.hasChanges();
        this.isSaveEnabled = this.isDiscardEnabled && !this.hasErrors();
        this.disableTestWorkspace = this.imanageSettings.databases && this.imanageSettings.databases.length <= 0 ? true : false;
    };
}