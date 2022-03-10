import { ChangeDetectionStrategy, Component, HostListener, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BehaviorSubject } from 'rxjs';
import { HostChildComponent } from 'shared/component/page/host-child-component';
import { IpxDomChangeHandlerDirective } from 'shared/directives/ipx-dom-change-handler.directive';
import { ComponentData, ComponentLoaderConfigService } from './component-loader-config';

@Component({
  selector: 'app-hosted',
  templateUrl: './hosted.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class HostedComponent implements OnInit, OnDestroy {
  @Input() stateParams: any;
  @ViewChild(IpxDomChangeHandlerDirective, { static: true }) domDirective: IpxDomChangeHandlerDirective;
  component$ = new BehaviorSubject<ComponentData>(null);
  private componentInstance: any;
  @HostListener('window:resize', ['$event']) onResize(event): void {
    if (!this.stateParams.deferLoad) {
      this.domDirective.triggerResize();
    }
  }

  private readonly componentKeyPairs = {
    searchResultHost: 'caseSearchResult',
    actionHost: 'caseViewActions',
    searchPresentationHost: 'searchPresentation',
    searchPresentationModalHost: 'searchPresentation',
    supplierHost: 'nameViewSupplier',
    trustHost: 'nameViewTrust',
    designElementHost: 'caseViewDesignElements',
    caseDMSHost: 'caseViewDocumentManagement',
    nameDMSHost: 'nameViewDocumentManagement',
    checklistHost: 'caseViewChecklist',
    fileLocationsHost: 'caseViewFileLocations',
    checklistWizardHost: 'checklistWizardHost',
    additionalCaseInfoHost: 'additionalCaseInfoHost',
    attachmentMaintenanceHost: 'attachmentMaintenance',
    startTimerForCaseHost: 'startTimerForCase',
    generateDocument: 'generateDocument',
    timerWidgetHost: 'timerWidget',
    affectedCasesHost: 'caseViewAffectedCases',
    adjustWipHost: 'adjustWip',
    splitWipHost: 'splitWip'
  };

  constructor(private readonly config: ComponentLoaderConfigService, private readonly rootScopeService: RootScopeService, private readonly windowParentMessagingService: WindowParentMessagingService) { }

  ngOnInit(): void {
    // tslint:disable-next-line: strict-boolean-expressions
    this.rootScopeService.rootScope.hostedProgramId = this.stateParams.programId || '';
    if (!this.stateParams.deferLoad) {
      this.loadComponent(this.stateParams);
    }
    this.registerListener();
    this.appOnInit();
  }
  private readonly registerListener = (): void => {
    if (window.addEventListener) {
      window.addEventListener('message', (e: Event) => {
        // tslint:disable-next-line:no-string-literal
        const data = e['data'];
        if (data === 'autoResize') {
          this.domDirective.triggerResize();
        } else if (data instanceof Object) { // TODO object typed
          switch (data.action) {
            case 'onInit':
              this.onInit(data);
              break;
            case 'onListenChanges':
              this.onListenChanges(data.payload);
              break;
            case 'onUnListenChanges':
              this.onUnListenChanges();
              break;
            case 'onNavigate':
              this.onNavigate();
              break;
            case 'onReload':
              this.onReload(data.payload);
              break;
            case 'onRequestDataResponseReceived':
              this.onRequestDataResponseReceived(data);
              break;
            default:
              break;
          }
        }
      });
    }
  };

  private readonly appOnInit = (): void => {
    this.windowParentMessagingService.postLifeCycleMessage({
      action: 'onInit', target: this.stateParams.hostId,
      payload: ''
    });
  };

  private readonly onInit = (data: any) => {
    this.loadComponent(data);
  };

  onViewInit = (comRef: Event): void => {
    this.componentInstance = comRef;
    this.windowParentMessagingService.postLifeCycleMessage({ action: 'onViewInit', target: this.stateParams.hostId });
    this.resize();
  };

  ngOnDestroy(): void {
    this.windowParentMessagingService.postLifeCycleMessage({ action: 'onDestroy', target: this.stateParams.hostId });
    document.removeEventListener('window:resize', () => {
      this.resize();
    });
  }

  private readonly onNavigate = (): void => {
    if (this.componentInstance) {
      (this.componentInstance as HostChildComponent).onNavigationAction();
    }
  };

  private readonly onReload = (data: any): void => {
    if (this.componentInstance && this.componentInstance.onReload) {
      this.componentInstance.onReload(data);
    } else if (this.componentInstance && this.componentInstance.componentRef && this.componentInstance.componentRef.onReload) {
      this.componentInstance.componentRef.onReload(data);
    }
  };

  private readonly onRequestDataResponseReceived = (data: any): void => {
    if (this.componentInstance && this.componentInstance.onRequestDataResponseReceived && this.componentInstance.onRequestDataResponseReceived[data.key]) {
      this.componentInstance.onRequestDataResponseReceived[data.key](data);
    } else if (this.componentInstance.componentRef && this.componentInstance.componentRef.onRequestDataResponseReceived && this.componentInstance.componentRef.onRequestDataResponseReceived[data.key]) {
      this.componentInstance.componentRef.onRequestDataResponseReceived[data.key](data);
    }
  };

  private readonly onListenChanges = (data: any): void => {
    if (this.componentInstance && (this.componentInstance as HostChildComponent)) {
      (this.componentInstance as HostChildComponent).setOnChangeAction({ action: 'onChange', target: this.stateParams.hostId, data: null }, this.windowParentMessagingService.postLifeCycleMessage);
      (this.componentInstance as HostChildComponent).setOnHostNavigation({ action: 'onNavigate', target: this.stateParams.hostId, data: data !== null ? data : null }, this.windowParentMessagingService.postLifeCycleMessage);
    }
  };

  private readonly onUnListenChanges = (): void => {
    if (this.componentInstance && (this.componentInstance as HostChildComponent)) {
      (this.componentInstance as HostChildComponent).setOnHostNavigation({ action: 'onNavigate', target: this.stateParams.hostId, data: null }, this.windowParentMessagingService.postLifeCycleMessage);
      (this.componentInstance as HostChildComponent).removeOnChangeAction();
    }
  };

  private readonly loadComponent = (params: any): void => {
    this.domDirective.triggerResize();
    this.config.initialize(params);
    const key = this.getKey(this.stateParams.hostId);
    this.component$.next(this.config.getConfiguration(key));
  };

  private readonly resize = (): void => {
    this.domDirective.triggerResize();
  };

  autoResize = (event: Event): void => {
    this.windowParentMessagingService.postAutosizeMessage({ height: Number(event), target: this.stateParams.hostId });
  };

  private readonly getKey = (key: string): string => {

    return this.componentKeyPairs[key];
  };
}

// TODO enum for lifesycle
