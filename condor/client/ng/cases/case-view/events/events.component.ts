import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { AttachmentModalService } from 'common/attachments/attachment-modal.service';
import { AppContextService } from 'core/app-context.service';
import { BusService } from 'core/bus.service';
import { LocalSetting, LocalSettings } from 'core/local-settings';
import { of } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { Topic, TopicGroup, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { MaintenanceTopicContract } from '../base/case-view-topics.base.component';
import { CaseDetailService } from '../case-detail.service';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { CaseViewViewData } from '../view-data.model';
import { CaseViewEventsService } from './events.service';

export interface CommonCaseViewData {
  importanceLevel: number;
  importanceLevelOptions: Array<any>;
  requireImportanceLevel: boolean;
  eventNoteTypes: Array<any>;
}

@Component({
  selector: 'ipx-case-view-events',
  templateUrl: './events.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [CaseViewEventsService, CaseDetailService, IpxDestroy]
})
export class CaseviewEventsComponent implements MaintenanceTopicContract, OnInit {
  topic: CaseEventsTopic;
  private readonly availableEventTypes = {
    due: 'due',
    occurred: 'occurred'
  };

  permissions = {
    canMaintainWorkflow: false,
    requireImportanceLevel: false,
    canViewNotes: false,
    canAddCaseAttachments: false
  };
  viewData: CaseViewViewData;
  eventType: any;
  importanceLevel: any;
  isExternal: boolean;
  gridOptions: IpxGridOptions;
  commonViewData: CommonCaseViewData;
  loaded = false;
  subscription: any;
  siteControlId: any;
  eventNotesLoaded: any;
  taskItems: any;

  @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
  @ViewChild('ipxHasNotesColumn', { static: true }) hasNotesCol: TemplateRef<any>;
  @ViewChild('caseViewEvents') grid: IpxKendoGridComponent;

  constructor(private readonly localSettings: LocalSettings,
    private readonly caseViewEventsService: CaseViewEventsService,
    private readonly caseDetailService: CaseDetailService,
    private readonly cdr: ChangeDetectorRef,
    private readonly bus: BusService,
    private readonly attachmentModalService: AttachmentModalService,
    private readonly destroy$: IpxDestroy,
    private readonly appContextService: AppContextService
  ) { }
  getChanges(): { [key: string]: any; } {
    throw new Error('Method not implemented.');
  }
  isValid?(): boolean {
    throw new Error('Method not implemented.');
  }
  onError(): void {
    throw new Error('Method not implemented.');
  }

  ngOnInit(): void {
    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe(ctx => {
        this.isExternal = ctx.user.isExternal;
      });

    this.viewData = this.topic.params.viewData;
    this.eventType = this.topic.params.eventType;

    this.caseDetailService.getImportanceLevelAndEventNoteTypes$()
      .subscribe((resp) => {
        this.importanceLevel = this.getDefaultImportanceLevel(resp.importanceLevel, resp.importanceLevelOptions);
        this.commonViewData = resp;
        this.permissions.canAddCaseAttachments = resp.canAddCaseAttachments;
        this.permissions.requireImportanceLevel = resp.requireImportanceLevel;
        this.permissions.canViewNotes = resp.eventNoteTypes && resp.eventNoteTypes.length > 0;
        this.gridOptions = this.buildGridOptions();
        this.loaded = true;
        this.cdr.markForCheck();
      });

    this.caseViewEventsService.siteControlId().subscribe(siteControl => {
      this.siteControlId = siteControl;
      this.eventNotesLoaded = true;
    });

    this.subscription = this.bus.channel('policingCompleted').subscribe(() => this.grid.search());
    this.watchAttachmentChanges();
  }

  private readonly getDefaultImportanceLevel = (importanceLevel: number, importanceLevelOptions: Array<{ code: number, description: string }>): number => {
    const cacheValue = this.localSettings.keys.caseView.events[this.eventType].importanceLevelCacheKey.getSession;
    if (cacheValue && _.find(importanceLevelOptions, (item: any) => {
      return item.code === cacheValue;
    })) {

      return cacheValue;
    }

    return importanceLevel;
  };

  changeImportanceLevel = (): void => {
    this.grid.search();
    (this.localSettings.keys.caseView.events[this.eventType].importanceLevelCacheKey as LocalSetting).setSession(this.importanceLevel);
  };

  private readonly buildGridOptions = (): IpxGridOptions => {
    const options: IpxGridOptions = {
      navigable: true,
      sortable: true,
      autobind: true,
      showGridMessagesUsingInlineAlert: false,
      reorderable: true,
      pageable: {
        pageSizes: [5, 10, 20, 50],
        pageSizeSetting: this.localSettings.keys.caseView.events[this.eventType].pageSize
      },
      selectable: {
        mode: 'single'
      },
      gridMessages: {
        noResultsFound: 'grid.messages.noItems',
        performSearch: ''
      },
      detailTemplate: this.detailTemplate,
      read$: (queryParams) => {
        if (this.eventType === this.availableEventTypes.due) {
          return this.caseViewEventsService.getCaseViewDueEvents(this.viewData.caseKey, Number(this.importanceLevel), queryParams);
        }

        if (this.eventType === this.availableEventTypes.occurred) {
          return this.caseViewEventsService.getCaseViewOccurredEvents(this.viewData.caseKey, Number(this.importanceLevel), queryParams);
        }

        return of([]);
      },
      columns: this.getColumns(),
      columnPicker: true,
      columnSelection: {
        localSetting: this.localSettings.keys.caseView.events[this.eventType].columnsSelection
      },
      onDataBound: () => {
        this.gridOptions._closeEditMode();
      },
      showContextMenu: !!this.permissions.canAddCaseAttachments
    };

    options.detailTemplateShowCondition = (dataItem: any): boolean => ((this.permissions.canViewNotes && dataItem.eventNotes && dataItem.eventNotes.length > 0) || dataItem.eventDueDate || dataItem.eventDefinition || dataItem.name || dataItem.fromCaseKey) && !this.isExternal;

    return options;
  };

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    const hasNotesColumns = this.permissions.canViewNotes ? [{
      title: '',
      width: 40,
      field: 'hasNotes',
      fixed: true,
      sortable: false,
      menu: false,
      template: this.hasNotesCol,
      includeInChooser: false
    }] : [];

    const notesColumns = this.permissions.canViewNotes ? [{
      title: 'caseview.actions.events.eventNotes',
      field: 'defaultEventText',
      menu: false,
      sortable: false,
      hidden: true,
      width: 500,
      template: true
    }] : [];

    const attachmentColumn = this.viewData.hasAccessToAttachmentSubject ? [{
      title: '',
      field: 'attachmentCount',
      width: 40,
      menu: false,
      template: true,
      sortable: false,
      fixed: true,
      includeInChooser: false
    }] : [];

    return [...hasNotesColumns,
    ...attachmentColumn,
    {
      title: 'caseview.events.date',
      field: 'eventDate',
      width: 150,
      fixed: true,
      menu: false,
      template: true,
      includeInChooser: false
    }, {
      title: 'caseview.events.eventDescription',
      field: 'eventDescription',
      width: 200,
      fixed: true,
      menu: false,
      includeInChooser: false
    }, ...notesColumns];
  };

  onMenuItemSelected = (menuEventDataItem: any): void => {
    menuEventDataItem.event.item.action(menuEventDataItem.dataItem);
  };

  displayTaskItems = (dataItem: any): void => {
    this.taskItems = [];
    if (this.permissions.canAddCaseAttachments) {
      this.taskItems.push({
        id: 'addAttachment',
        text: 'caseview.actions.events.addAttachment',
        icon: 'cpa-icon cpa-icon-paperclip',
        action: this.addAttachment
      });
    }
  };

  addAttachment = (dataItem: any): void => {
    this.attachmentModalService.triggerAddAttachment('case', this.viewData.caseKey, { eventKey: dataItem.eventNo, eventCycle: dataItem.cycle, actionKey: dataItem.createdByAction });
  };

  openAttachmentWindow = (dataItem: any): void => {
    this.attachmentModalService.displayAttachmentModal('case', this.viewData.caseKey, {
      actionKey: dataItem.createdByAction,
      eventKey: dataItem.eventNo,
      eventCycle: dataItem.cycle
    });
  };

  private readonly watchAttachmentChanges = (): void => {
    this.attachmentModalService.attachmentsModified
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.grid.search();
        this.cdr.markForCheck();
      });
  };
}

export class CaseEventsGroupTopic extends TopicGroup {
  readonly key = 'eventsGroup';
  readonly title = caseViewTopicTitles.events;
  readonly topics: Array<Topic>;
  constructor(public params: TopicParam) {
    super();
    this.topics = [
      new CaseEventsTopic('due', caseViewTopicTitles.eventsDue, {
        viewData: params.viewData,
        eventType: 'due'
      }),
      new CaseEventsTopic('occurred', caseViewTopicTitles.eventsOccurred, {
        viewData: params.viewData,
        eventType: 'occurred'
      })
    ];
  }
}

export class CaseEventsTopic extends Topic {
  readonly component = CaseviewEventsComponent;
  constructor(public key: string, public title: string, public params: CaseEventsTopicParams) {
    super();
  }
}

export class CaseEventsTopicParams extends TopicParam {
  eventType: string;
}