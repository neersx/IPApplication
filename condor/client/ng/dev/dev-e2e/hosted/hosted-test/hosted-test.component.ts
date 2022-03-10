import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Renderer2, ViewChild } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MessageType } from 'core/window-parent-messaging.service';

@Component({
  selector: 'app-hosted-test',
  templateUrl: './hosted-test.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class HostedTestComponent {
  @ViewChild('iframe') iframe: ElementRef;

  postMessage = '';
  constructor(private readonly renderer: Renderer2, private readonly cdr: ChangeDetectorRef, private readonly sanitizer: DomSanitizer) {
    this.postMessage = JSON.stringify({ queryContextKey: 2 });
    renderer.listen('window', 'message', this.onPostMessage.bind(this));
  }
  receivedNavigationMessages = '';
  receivedAutoSizeMessages = '';
  receivedLifeCycleMessages = '';
  selectedUrl: SafeResourceUrl;
  selectedComponent: ComponentModel = null;
  components: Array<ComponentModel> = [
    {
      id: 1,
      displayName: 'Hosted Search Results',
      url: './index.html#/hosted/search/searchresult?deferLoad=true&hostId=searchResultHost',
      defaultPostMessage: JSON.stringify({ queryContextKey: 2 }),
      componentType: ComponentType.default
    },
    {
      id: 2,
      displayName: 'Hosted Search Presentation',
      url: './index.html#/hosted/search/presentation?hostId=searchPresentationModalHost&deferLoad=true',
      defaultPostMessage: JSON.stringify({ queryContextKey: 2 }),
      componentType: ComponentType.default
    },
    {
      id: 3,
      displayName: 'Hosted Case View Actions',
      url: './index.html#/hosted/CaseView/{CaseKey}?programId={Program}&section=actions&hostId=actionHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: true }),
      componentType: ComponentType.caseTopic,
      case: null,
      program: null
    },
    {
      id: 4,
      displayName: 'Hosted Name View Supplier',
      url: './index.html#/hosted/NameView/{NameKey}?&hostId=supplierHost',
      defaultPostMessage: JSON.stringify({ NameKey: 7 }),
      componentType: ComponentType.nameTopic,
      name: null
    },
    {
      id: 5,
      displayName: 'Hosted Name View Trust Accounting',
      url: './index.html#/hosted/NameView/{NameKey}?&hostId=trustHost',
      defaultPostMessage: JSON.stringify({ NameKey: 7 }),
      componentType: ComponentType.nameTopic,
      name: null
    },
    {
      id: 6,
      displayName: 'Hosted Case View Design Elements',
      url: './index.html#/hosted/CaseView/{CaseKey}?programId={Program}&section=designElement&hostId=designElementHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: true }),
      componentType: ComponentType.caseTopic,
      case: null,
      program: null
    },
    {
      id: 7,
      displayName: 'Hosted Case View DMS',
      url: './index.html#/hosted/CaseView/{CaseKey}?programId={Program}&section=caseDocumentManagementSystem&hostId=caseDMSHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: true }),
      componentType: ComponentType.caseTopic,
      case: null,
      program: null
    },
    {
      id: 8,
      displayName: 'Hosted Name View DMS',
      url: './index.html#/hosted/NameView/{NameKey}?programId={Program}&section=nameDocumentManagementSystem&hostId=nameDMSHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: true }),
      componentType: ComponentType.nameTopic,
      case: null,
      program: null
    },
    {
      id: 9,
      displayName: 'Hosted Case View Checklist',
      url: './index.html#/hosted/CaseView/{CaseKey}?programId={Program}&section=checklist&hostId=checklistHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: false }),
      componentType: ComponentType.caseTopic,
      case: null,
      program: null
    },
    {
      id: 10,
      displayName: 'Hosted Case View File Location',
      url: './index.html#/hosted/CaseView/{CaseKey}?programId={Program}&section=fileLocations&hostId=fileLocationsHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: false }),
      componentType: ComponentType.caseTopic,
      case: null,
      program: null
    },
    {
      id: 11,
      displayName: 'Hosted Workflow Wizard Checklist',
      url: './index.html#/hosted/CaseView/{CaseKey}?programId={Program}&section=checklist&hostId=checklistWizardHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: false }),
      componentType: ComponentType.caseTopic,
      case: null,
      program: null
    },
    {
      id: 12,
      displayName: 'Hosted Case Attachment',
      url: './index.html#/hosted/attachmentMaintenance/case/{CaseKey}?hostId=attachmentMaintenanceHost&activityKey={activityId}&sequenceKey={sequenceKey}',
      defaultPostMessage: '',
      componentType: ComponentType.attachment,
      case: null,
      name: null,
      activityId: null,
      sequenceNo: null
    },
    {
      id: 13,
      displayName: 'Hosted Name Attachment',
      url: './index.html#/hosted/attachmentMaintenance/name/{NameKey}?hostId=attachmentMaintenanceHost&activityKey={activityId}&sequenceKey={sequenceKey}',
      defaultPostMessage: '',
      componentType: ComponentType.attachment,
      case: null,
      name: null,
      activityId: null,
      sequenceNo: null
    },
    {
      id: 14,
      displayName: 'Hosted Contact Activity Attachment',
      url: './index.html#/hosted/attachmentMaintenance/activity?hostId=attachmentMaintenanceHost&activityKey={activityId}&sequenceKey={sequenceKey}',
      defaultPostMessage: '',
      componentType: ComponentType.attachment,
      case: null,
      name: null,
      activityId: null,
      sequenceNo: null
    },
    {
      id: 15,
      displayName: 'Hosted Enter Time with Timer',
      url: './index.html#/hosted/startTimerFor/case?hostId=startTimerForCaseHost&caseKey={CaseKey}',
      defaultPostMessage: '',
      componentType: ComponentType.Timesheet,
      case: null,
      name: null,
      activityId: null,
      sequenceNo: null
    },
    {
      id: 16,
      displayName: 'Hosted Generate Document Case',
      url: './index.html#/hosted/generateDocument?hostId=generateDocument&irn={CaseIrn}&caseKey={CaseKey}&isWord={IsWord}&isCase=1&isE2e=1',
      defaultPostMessage: '',
      componentType: ComponentType.generateDocument
    },
    {
      id: 17,
      displayName: 'Hosted Generate Document Name',
      url: './index.html#/hosted/generateDocument?hostId=generateDocument&nameKey={NameKey}&isWord={IsWord}&isCase=0&isE2e=1',
      defaultPostMessage: '',
      componentType: ComponentType.generateDocument
    },
    {
      id: 18,
      displayName: 'Hosted Case Affected Cases',
      url: './index.html#/hosted/CaseView/{CaseKey}?programId={Program}&section=affectedCases&hostId=affectedCasesHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: false }),
      componentType: ComponentType.caseTopic,
      case: null,
      program: null
    },
    {
      id: 19,
      displayName: 'Hosted Adjust Wip',
      url: './index.html#/hosted/adjustWip?entityKey={EntityKey}&transKey={TransKey}&wipSeqKey={WIPSeqKey}&hostId=adjustWipHost',
      defaultPostMessage: '',
      componentType: ComponentType.adjustWip,
      case: null,
      program: null
    },
    {
      id: 20,
      displayName: 'Hosted Split Wip',
      url: './index.html#/hosted/splitWip?entityKey={EntityKey}&transKey={TransKey}&wipSeqKey={WIPSeqKey}&hostId=splitWipHost',
      defaultPostMessage: JSON.stringify({ key: 'isPoliceImmediately', value: false }),
      componentType: ComponentType.splitWip,
      case: null,
      program: null
    }
  ];

  sendEvent = (action: string) => {
    const parsedPost = this.postMessage ? JSON.parse(this.postMessage) : {};
    this.iframe.nativeElement.contentWindow.postMessage({ ...parsedPost, action }, '*');
  };

  onPostMessage(event): void {
    const receivedMessage = JSON.stringify(event.data) + '\n';
    switch (event.data.type) {
      case MessageType.autoSize:
        this.receivedAutoSizeMessages += receivedMessage;
        break;
      case MessageType.lifecycle:
        this.receivedLifeCycleMessages += receivedMessage;
        break;
      case MessageType.navigation:
        this.receivedNavigationMessages += receivedMessage;
        break;
      default:
        break;
    }
    this.cdr.markForCheck();
  }

  onComponentChange(event: ComponentModel): void {
    this.receivedNavigationMessages = '';
    this.receivedAutoSizeMessages = '';
    this.receivedLifeCycleMessages = '';
    this.postMessage = event.defaultPostMessage;
    switch (event.componentType) {
      case ComponentType.default:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(event.url);
        this.cdr.markForCheck();
        break;
      default:
        break;
    }
  }

  loadCaseTopic(): void {
    this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url.replace('{CaseKey}', this.selectedComponent.case.key.toString()).replace('{Program}', this.selectedComponent.program.key));
  }
  loadNameTopic(): void {
    this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url.replace('{NameKey}', this.selectedComponent.name.key.toString()));
  }

  loadAttachment(): void {
    switch (this.selectedComponent.id) {
      case 12:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url.replace('{CaseKey}', this.selectedComponent.case.key.toString())
          .replace('{activityId}', this.selectedComponent.activityId)
          .replace('{sequenceKey}', this.selectedComponent.sequenceNo));
        break;
      case 13:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url.replace('{NameKey}', this.selectedComponent.name.key.toString())
          .replace('{activityId}', this.selectedComponent.activityId)
          .replace('{sequenceKey}', this.selectedComponent.sequenceNo));
        break;
      case 14:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url
          .replace('{activityId}', this.selectedComponent.activityId)
          .replace('{sequenceKey}', this.selectedComponent.sequenceNo));
        break;
      case 15:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url);
        break;
      default: break;
    }
  }

  loadGenerateDocument(): void {
    switch (this.selectedComponent.id) {
      case 16:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url
          .replace('{CaseKey}', this.selectedComponent.case.key.toString())
          .replace('{CaseIrn}', encodeURIComponent(this.selectedComponent.case.code))
          .replace('{IsWord}', ((this.selectedComponent.isWord || false) ? 1 : 0).toString()));
        break;
      case 17:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url
          .replace('{NameKey}', this.selectedComponent.name.key.toString())
          .replace('{IsWord}', ((this.selectedComponent.isWord || false) ? 1 : 0).toString()));
        break;
      default: break;
    }
  }

  loadWipAdjustmentDetails(): void {
    switch (this.selectedComponent.id) {
      case 19:
        this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url
          .replace('{EntityKey}', this.selectedComponent.entityId.toString())
          .replace('{TransKey}', this.selectedComponent.transKey.toString())
          .replace('{WIPSeqKey}', this.selectedComponent.wipSeqKey.toString()));
        break;
      default: break;
    }
  }

  startTimer(): void {
    this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url.replace('{CaseKey}', this.selectedComponent.case.key.toString()));
  }

  loadSplitWip(): void {
    this.selectedUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.selectedComponent.url
      .replace('{EntityKey}', this.selectedComponent.entityId.toString())
      .replace('{TransKey}', this.selectedComponent.transKey.toString())
      .replace('{WIPSeqKey}', this.selectedComponent.wipSeqKey.toString()));
  }
}

class ComponentModel {
  id: number;
  displayName: string;
  url: string;
  defaultPostMessage: string;
  componentType: ComponentType;
  case?: { key: number, code: string };
  program?: { key: string };
  name?: { key: number };
  activityId?: string;
  sequenceNo?: string;
  isWord?: boolean;
  entityId?: number;
  transKey?: number;
  wipSeqKey?: number;
}

enum ComponentType {
  default, caseTopic, nameTopic, attachment, Timesheet, generateDocument, adjustWip, splitWip
}