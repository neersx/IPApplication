import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { iif } from 'rxjs';
import { map, takeUntil } from 'rxjs/operators';
import { TopicContainer, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { SanityCheckConfigurationService } from '../sanity-check-configuration.service';
import { NamesSanityCheckRuleModel, SanityCheckCaseRule, SanityCheckNameRule, SanityCheckRuleModelEx } from './maintenance-model';
import { SanityCheckMaintenanceService } from './sanity-check-maintenance.service';
import { SanityCheckCaseCharacteristicsTopic, SanityCheckCaseNameTopic, SanityCheckEventTopic, SanityCheckNameCharacteristicsTopic, SanityCheckOtherTopic, SanityCheckRuleOverviewTopic, SanityCheckStandingInstructionTopic } from './sanity-check.topics';
@Component({
    selector: 'app-sanity-maintenance',
    templateUrl: './sanity-check-maintenance.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class SanityCheckConfigurationMaintenanceComponent extends TopicContainer implements OnInit, AfterViewInit {
    @Input() stateParams: any;
    @Input() viewData: any;
    isEditMode = false;
    matchType: string;
    navData: any;
    topicOptions: TopicOptions;
    isDiscardEnabled = false;
    isSaveEnabled = false;
    navigationState: string;
    validationId: any;
    isPageDirty = (): boolean => this.isDiscardEnabled;

    constructor(private readonly state: StateService, private readonly service: SanityCheckMaintenanceService, private readonly notificationService: NotificationService,
        private readonly cdr: ChangeDetectorRef, private readonly searchService: SanityCheckConfigurationService, private readonly destroy$: IpxDestroy, private readonly shortcutService: IpxShortcutsService) {
        super();
    }

    ngAfterViewInit(): void {
        this.cdr.markForCheck();
    }

    ngOnInit(): void {
        this.matchType = this.stateParams.matchType;

        this.navigationState = this.state.current.name;
        this.navData = this.searchService.getNavData();

        switch (this.matchType) {
            case 'case': this.initCaseData();
                break;
            case 'name': this.initNameData();
                break;
            default: break;
        }

        this.service.hasErrors$
            .pipe(map(this.updateUIStates))
            .pipe(takeUntil(this.destroy$))
            .subscribe();

        this.service.hasPendingChanges$
            .pipe(map(this.updateHasChanges))
            .pipe(takeUntil(this.destroy$))
            .subscribe();

        this.handleShortcuts();
    }

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.REVERT, (): void => { if (this.isDiscardEnabled) { this.reload(); } }],
            [RegisterableShortcuts.SAVE, (): void => { if (this.isSaveEnabled) { this.save(); } }]]);

        this.shortcutService.observeMultiple$([RegisterableShortcuts.REVERT, RegisterableShortcuts.SAVE])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    initCaseData(): void {
        const id = this.stateParams.id;
        if (!!id && !!this.viewData) {
            const modelEx = new SanityCheckRuleModelEx(this.viewData);
            this.initializeCaseTopics(modelEx.convertToCaseRuleModel());
            this.isEditMode = true;
            this.validationId = this.stateParams.id;
        } else {
            this.initializeCaseTopics();
        }
    }

    initNameData(): void {
        const id = this.stateParams.id;
        if (!!id && !!this.viewData) {
            const model = new NamesSanityCheckRuleModel(this.viewData);
            this.initializeNameTopics(model);
            this.isEditMode = true;
            this.validationId = this.stateParams.id;
        } else {
            this.initializeNameTopics();
        }
    }

    reload = () => {
        this.isDiscardEnabled = false;
        this.state.reload(this.state.current.name);
    };

    save = () => {
        this.isSaveEnabled = false;
        let data = { validationId: this.validationId } as any;
        this.topicOptions.topics.forEach(t => data = { ...data, ...(t.getDataChanges !== undefined ? t.getDataChanges() : {}) });
        this.saveSettings(data);
    };

    private readonly initializeCaseTopics = (data: SanityCheckCaseRule = null): void => {
        const topics = {
            ruleOverview: new SanityCheckRuleOverviewTopic({
                viewData: data?.ruleOverView
            }),
            caseCharacteristics: new SanityCheckCaseCharacteristicsTopic({
                viewData: data?.caseCharacteristics
            }),
            caseName: new SanityCheckCaseNameTopic({
                viewData: data?.caseName
            }),
            standingInstruction: new SanityCheckStandingInstructionTopic({
                viewData: data?.standingInstruction
            }),
            event: new SanityCheckEventTopic({
                viewData: data?.event
            }),
            other: new SanityCheckOtherTopic({
                viewData: data?.other,
                matchType: this.matchType
            })
        };
        this.topicOptions = {
            topics: [
                topics.ruleOverview,
                topics.caseCharacteristics,
                topics.caseName,
                topics.standingInstruction,
                topics.event,
                topics.other
            ],
            actions: []
        };
    };

    private readonly initializeNameTopics = (data: SanityCheckNameRule = null): void => {
        const topics = {
            ruleOverview: new SanityCheckRuleOverviewTopic({
                viewData: data?.ruleOverView
            }),
            nameCharacteristics: new SanityCheckNameCharacteristicsTopic({
                viewData: data?.nameCharacteristics
            }),
            standingInstruction: new SanityCheckStandingInstructionTopic({
                viewData: data?.standingInstruction
            }),
            other: new SanityCheckOtherTopic({
                viewData: data?.other,
                matchType: this.matchType
            })
        };
        this.topicOptions = {
            topics: [
                topics.ruleOverview,
                topics.nameCharacteristics,
                topics.standingInstruction,
                topics.other
            ],
            actions: []
        };
    };

    private readonly updateHasChanges = () => {
        this.isDiscardEnabled = this.hasChanges();
        this.cdr.markForCheck();
    };

    private readonly updateUIStates = (hasErrors: boolean = null) => {
        this.isSaveEnabled = this.isDiscardEnabled && !this.hasErrors() && (hasErrors == null ? true : !hasErrors);
        this.cdr.markForCheck();
    };

    private readonly saveSettings = (data: any) => {
        iif(() => !!data.validationId,
            this.service.update$(this.matchType, { ...data }),
            this.service.save$(this.matchType, { ...data }))
            .subscribe((response) => {
                if (response) {
                    this.notificationService.success();
                    this.service.resetChangeEventState();
                    this.isDiscardEnabled = false;
                    if (!!data.validationId) {
                        this.state.reload();
                    } else {
                        this.stateParams.id = response.id;
                        this.state.transitionTo('sanityCheckMaintenanceEdit', this.stateParams);
                    }
                } else {
                    this.isSaveEnabled = false;
                    this.service.resetChangeEventState();
                    this.notificationService.alert({ message: 'unSavedChanges' });
                }
            }, error => {
                this.isSaveEnabled = true;
            }, () => {
                this.cdr.markForCheck();
            });
    };
}