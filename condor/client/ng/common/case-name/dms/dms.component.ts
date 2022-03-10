import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, HostListener, Input, NgZone, OnDestroy, OnInit, Output, ViewChild } from '@angular/core';
import { TreeViewComponent } from '@progress/kendo-angular-treeview';
import { caseViewTopicTitles } from 'cases/case-view/case-view-topic-titles';
import { AppContextService } from 'core/app-context.service';
import { MessageBroker } from 'core/message-broker';
import { WindowRef } from 'core/window-ref';
import { Observable, of } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { DmsViewData } from './dms-view-data';
import { DmsPersistenceService } from './dms.persistence.service';
import { DmsService } from './dms.service';
import { selectedDocument } from './dms.types';

@Component({
  selector: 'dms',
  templateUrl: './dms.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DmsComponent implements TopicContract, OnInit, OnDestroy {
  @Input() topic: DmsTopic;
  @Output() readonly onDocumentSelectedIwl = new EventEmitter<selectedDocument>();
  dmsViewData: DmsViewData;
  selectedId: {
    siteDbId: number,
    containerId: string,
    folderType: string,
    canHaveRelatedDocuments: boolean
  };
  data: Array<any>;
  key: number;
  errors: Array<string>;
  callerType: 'CaseView' | 'NameView';
  expandedKeys = ['0'];
  selectedKeys = ['0'];
  folderTypeIconMap = {
    ['folder']: 'folder',
    ['workspace']: 'workspace',
    ['emailFolder']: 'envelope',
    ['searchFolder']: 'folder-search'
  };
  workspaceIwl: string;
  treeLoading = true;
  ctx: any;
  subscription: any;

  constructor(readonly service: DmsService, private readonly cdr: ChangeDetectorRef, private readonly messageBroker: MessageBroker, private readonly persistanceService: DmsPersistenceService, private readonly windoeRef: WindowRef) { }

  ngOnInit(): void {
    this.setKeyData(this.topic.params);
    this.loadData();
  }

  ngOnDestroy(): void {
    this.service.disconnectBindings();
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  documentSelected = (doc: selectedDocument) => {
    this.onDocumentSelectedIwl.emit(doc);
  };

  hasAnyChidFolderOrDocument = (node: any): void => {
    if (node && Array.isArray(node)) {
      node.forEach(childEle => {
        this.setFolderEmpty(childEle);
      });
    } else {
      this.setFolderEmpty(node);
    }

    if (node.hasChildFolders) {
      this.hasAnyChidFolderOrDocument(node.childFolders);
    }
  };

  private readonly setFolderEmpty = (node: any): void => {
    (node.hasChildFolders || node.hasDocuments || node.folderType === 'searchFolder') ? node.isFolderEmpty = false : node.isFolderEmpty = true;
  };

  loadData = () => {
    this.service.getViewData$().subscribe((viewData) => {
      this.dmsViewData = viewData;
      this.cdr.markForCheck();
      if (!viewData.errors) {
        this.service.getDmsFolders$({ callerType: this.callerType }, this.key)
          .subscribe((d: { folders: Array<any>, errors: Array<string>, isOAuth2AuthenticationRequired: boolean }) => {
            this.data = d.folders;
            this.treeLoading = false;
            this.cdr.markForCheck();
            if (d.errors && d.errors.length !== 0) {
              this.errors = d.errors;
            }

            if (this.data && d.folders.length > 0) {
              this.handleSelection({ dataItem: this.data[0] });
            }
            this.cdr.detectChanges();
          });
      } else {
        this.errors = [viewData.errors];
        this.cdr.detectChanges();
      }
    });
  };

  signingIn = false;
  loginDms = () => {
    this.signingIn = true;
    this.cdr.markForCheck();

    this.service.loginDms().then((success) => {
      this.signingIn = false;
      this.cdr.markForCheck();

      if (success) {
        this.loadData();
      }
      this.cdr.markForCheck();
    });

    this.treeLoading = true;
    this.cdr.markForCheck();
  };

  hasChildren = (node: any): boolean => {
    return node.hasChildFolders;
  };

  fetchChildren = (node: any): Observable<Array<any>> => {
    const hasFolders = this.persistanceService.hasPersistedFolders(node);
    if (hasFolders && node) {
      this.hasAnyChidFolderOrDocument(node);
    }

    return hasFolders ? of(this.persistanceService.folders$.getValue()) : this.fetchOriginalFolders(node);
  };

  fetchOriginalFolders(node): any {
    return this.service.getDmsChildFolders$(node.siteDbId, node.containerId, node.folderType, false)
      .pipe(map(res => {
        node.childFolders = res;

        if (res && res.length > 0) {
          this.hasAnyChidFolderOrDocument(res);
        }

        return res;
      }));
  }

  handleSelection = (node: any): void => {
    if (node && node.index) {
      this.selectedKeys = [node.index];
    }
    this.selectedId = {
      siteDbId: node.dataItem.siteDbId,
      containerId: node.dataItem.containerId,
      folderType: node.dataItem.folderType,
      canHaveRelatedDocuments: node.dataItem.canHaveRelatedDocuments
    };

    if (this.selectedId && this.selectedId.siteDbId && this.selectedKeys && this.selectedKeys.length === 1) {
      const workSpaceIndex = this.selectedKeys[0].substring(0, 1);
      this.workspaceIwl = this.data[workSpaceIndex].iwl;
    }
    this.documentSelected({} as any);
    this.cdr.detectChanges();
  };

  openIniManage = (): void => {
    if (this.workspaceIwl) {
      this.windoeRef.nativeWindow.open(this.workspaceIwl, '_blank');
    }
  };

  private readonly setKeyData = (params: DMsTopicParam): void => {
    this.callerType = params.callerType;
    this.key = params.callerType === 'NameView' ? params.viewData.nameId
      : params.viewData.caseKey;
  };
}

export class DMsTopicParam extends TopicParam {
  callerType: 'CaseView' | 'NameView';
}

export class DmsTopic extends Topic {
  readonly key = 'dms';
  readonly title = caseViewTopicTitles.dms;
  readonly component = DmsComponent;
  constructor(public params: DMsTopicParam) {
    super();
  }
}
