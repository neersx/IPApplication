import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ComponentFactoryResolver, ComponentRef, EventEmitter, Injector, OnInit, Output, TemplateRef, Type, ViewChild } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSetting, LocalSettings } from 'core/local-settings';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, Observable, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { TaskPlannerPersistenceService } from 'search/task-planner/task-planner-persistence.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { getComponent } from 'shared/component/utility/type.decorator';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { PicklistTemplateType } from '../../ipx-autocomplete/autocomplete/template.type';
import { IpxPicklistMaintenanceService } from '../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-modal-maintenance/ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';
import { IpxPicklistModelHostDirective } from '../ipx-picklist-modal-maintenance/ipx-picklist-maintenance-templates/ipx-picklist-model-host.directive';
import { IpxModalOptions } from '../ipx-picklist-modal-options';
import { IpxPicklistModalSearchResultsComponent } from '../ipx-picklist-modal-search-results/ipx-picklist-modal-search-results.component';
import { IpxPicklistSearchFieldComponent, NavigationEnum } from '../ipx-picklist-search-field/ipx-picklist-search-field.component';

@Component({
    selector: 'ipx-picklist-modal',
    templateUrl: 'ipx-picklist-modal.component.html',
    providers: [IpxPicklistMaintenanceService, GridNavigationService, IpxDestroy],
    changeDetection: ChangeDetectionStrategy.OnPush,
    styles: ['.withColumnPicker { width:calc(100% - 25px); float:left; }']
})
export class IpxPicklistModalComponent implements OnInit, AfterViewInit {
    @ViewChild('searchResult') searchResult: IpxPicklistModalSearchResultsComponent;
    @ViewChild('valid') validTemplate: TemplateRef<any>;
    @ViewChild('NameFiltered') nameFiltered: TemplateRef<any>;
    @ViewChild('blank') blankTemplate: TemplateRef<any>;
    @ViewChild('viewModeHeader') viewModeHeader: TemplateRef<any>;
    @ViewChild('maintenanceHeader') maintenanceHeader: TemplateRef<any>;
    @ViewChild('navigationHeader') navigationHeader: TemplateRef<any>;
    @ViewChild('designationStage') designationStageTemplate: TemplateRef<any>;
    @ViewChild('name') name: TemplateRef<any>;
    @ViewChild('default') defaultTemplate: TemplateRef<any>;
    @ViewChild(IpxPicklistModelHostDirective, { static: true }) dynamicHost: IpxPicklistModelHostDirective;
    @ViewChild('picklistSearchField') picklistSearchField: IpxPicklistSearchFieldComponent;
    modalOptions: IpxModalOptions;
    splitterOptions: any;
    typeaheadOptions: any;
    externalScope: any;
    storeSearchValue = new BehaviorSubject('');

    private _isPreviewActive: boolean;
    get isPreviewActive(): boolean {
        return this._isPreviewActive;
    }

    set isPreviewActive(value: boolean) {
        this._isPreviewActive = value;
        this.previewActiveSetting.setLocal(value);
    }

    previewActiveSetting: LocalSetting;
    entry: any;
    maintananceTitle: string;
    selectedRow$ = new Subject(); // TODO need to be moved to other places
    onClose$ = new Subject();
    configuredTemplate$ = new Subject();
    configuredHeaderTemplate$ = new Subject();
    configuredNavigationHeader$ = new Subject();
    isMaintenanceMode$ = new BehaviorSubject('');
    selectedItemKey: any;
    private readonly modalRef: BsModalRef;
    private componentRef: ComponentRef<PicklistMainainanceComponent>;
    values = [];
    isAddAnotherChecked = false;
    extendedActions: any;
    canNavigate: Boolean;
    navData: {
        keys: Array<any>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };
    currentKey: number;

    constructor(bsModalRef: BsModalRef, private readonly resolver: ComponentFactoryResolver,
        public service: IpxPicklistMaintenanceService, private readonly localSettings: LocalSettings,
        private readonly notificationService: NotificationService,
        private readonly gridNavService: GridNavigationService,
        private readonly cdRef: ChangeDetectorRef,
        private readonly shortcutsService: IpxShortcutsService,
        private readonly destroy$: IpxDestroy,
        private readonly persistenceService: TaskPlannerPersistenceService,
        private readonly injector: Injector) {
        this.modalRef = bsModalRef;
    }

    shortcutCallbacksMap = new Map(
        [[RegisterableShortcuts.ADD, () => {
            if (this.modalOptions.picklistCanMaintain) {
                this.onAdd();
            }
        }],
        [RegisterableShortcuts.SAVE, () => { this.onSave(); }]]);

    private readonly initShortcuts = () => {
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.ADD, RegisterableShortcuts.SAVE])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && this.shortcutCallbacksMap.has(key)) {
                    this.shortcutCallbacksMap.get(key)();
                }
            });
    };

    ngOnInit(): void {
        if (this.modalOptions.canNavigate) {
            this.service.initNavigationOptions(this.typeaheadOptions.apiUrl, this.typeaheadOptions.keyField);
        }

        this.initShortcuts();
        // callback the function defined in the consumer of the picklist only if it is of function type, otherwise simply assign it
        if (this.modalOptions.externalScope) {
            this.externalScope = _.isFunction(this.modalOptions.externalScope) ? this.modalOptions.externalScope() : this.modalOptions.externalScope;
        }
        if (this.modalOptions.selectedItems && this.modalOptions.selectedItems.length > 0) {
            this.values = this.modalOptions.selectedItems;
        }
        this.previewActiveSetting = this.localSettings.keys.typeahead.picklist.previewActive;
        this.isPreviewActive = this.typeaheadOptions.previewable ? (this.previewActiveSetting.getLocal === true ? true : false) : false;
        if (this.modalOptions.extendedParams && _.isFunction(this.modalOptions.extendedParams)) {
            this.extendedActions = this.modalOptions.extendedParams().extendedActions;
        }
        if (this.modalOptions.searchValue) {
            this.storeSearchValue.next(this.modalOptions.searchValue);
        }
    }

    getResultGridData = (): Array<any> => {
        let results: Array<any>;
        if (this.searchResult && this.searchResult.resultGrid) {
            results = this.searchResult.resultGrid.getCurrentData();
        }

        return results;
    };

    ngAfterViewInit(): void {
        this.switchTemplatesHookup();
    }

    extendParams = (value): any => {
        if (this.modalOptions.extendedParams) {
            if (value.action === 'edit') {
                value.value = _.extend(this.modalOptions.extendedParams(), value.value);
            } else if (value.action === 'add') {
                value.value = _.extend({}, this.modalOptions.extendedParams());
            }
        }
    };

    excuteAction = (value: { value: any, action: any }) => {
        this.extendParams(value);
        switch (value.action) {
            case 'add':
            case 'duplicate':
            case 'edit':
            case 'view':
                this.canNavigate = this.modalOptions.canNavigate
                    && (value.action === 'edit' || value.action === 'view');
                this.maintananceTitle = this.getMaintainanceTitle(value.action);
                this.entry = value.value;
                if (value.action === 'duplicate') {
                    delete this.entry.key;
                    if (this.entry.code) {
                        this.entry.code = '';
                    }
                }
                this.isMaintenanceMode$.next(value.action);
                this.service.nextMaintenanceMode(value.action);
                this.configuredTemplate$.next(this.blankTemplate);
                const metaData = this.service.maintenanceMetaData$.getValue();
                if (metaData && metaData.maintainabilityActions) {
                    metaData.maintainabilityActions.action = value.action;
                    this.service.nextMaintenanceMetaData(metaData);
                }
                if (this.modalOptions.canNavigate && (value.action === 'edit' || value.action === 'view')) {
                    this.navData = this.gridNavService.getNavigationData();
                    this.currentKey = this.navData.keys.filter(k => k.value === this.entry.key.toString())[0].key;
                }
                if (this.canNavigate) {
                    this.fetchPicklistItem().subscribe(result => {
                        this.entry = _.extend(this.entry, result);
                        this.loadComponent(this.typeaheadOptions.maintenanceTemplate);
                        this.cdRef.markForCheck();
                    });
                } else {
                    this.loadComponent(this.typeaheadOptions.maintenanceTemplate);
                }
                break;
            case 'delete':
                this.onDelete(value.value);
                break;
            default:
                return '';
        }
    };

    fetchPicklistItem = (): Observable<any> => {
        return this.service.getItem$(this.typeaheadOptions, this.entry);
    };

    private readonly getMaintainanceTitle = (action: 'add' | 'duplicate' | 'edit' | 'view' | 'delete'): string => {
        switch (action) {
            case 'add':
            case 'duplicate':
                return 'picklistmodal.add';
            case 'edit':
                return 'picklistmodal.edit';
            case 'view':
                return 'picklistmodal.view';
            default:
                return '';
        }
    };

    loadComponent(componentName: string): void {
        const component = getComponent(componentName) as Type<any>;
        const componentFactory = this.resolver.resolveComponentFactory(component);
        this.dynamicHost.viewContainerRef.clear();
        this.componentRef = this.dynamicHost.viewContainerRef.createComponent(componentFactory);
        this.componentRef.instance.entry = this.entry;
        this.componentRef.instance.extendedActions = this.extendedActions;
    }

    getNextItemDetail(next: number): any {
        this.entry.key = next;
        this.componentRef.instance.form.markAsPristine();
        this.fetchPicklistItem().subscribe(result => {
            this.entry = _.extend(this.entry, result);
            this.loadComponent(this.typeaheadOptions.maintenanceTemplate);
            this.cdRef.markForCheck();
            this.updateModalState();
        });
    }

    updateModalState = () => {
        const state = this.service.modalStates$.getValue();
        state.canSave = false;
        this.service.nextModalState(state);
    };

    hasUnsavedChanges = () => {
        return this.componentRef
            && this.componentRef.instance.form
            && this.componentRef.instance.form.dirty;
    };

    updateRows(data): void {
        this.values = data.value;

        if (!this.modalOptions.multipick && !data.isSortingEvent) {
            this.onApply();
        }
    }

    updateSelection(dataItem): void {
        if (!dataItem) {
            return;
        }
        if (this.extendedActions && this.extendedActions.picklistCanMaintain) {
            const caseList = _.extend({ newlyAddedCaseKeys: this.modalOptions.extendedParams().caseKeys }, dataItem);
            caseList.newlyAddedCaseKeys = _.difference(caseList.newlyAddedCaseKeys, caseList.caseKeys);
            caseList.caseKeys = caseList.caseKeys.concat(caseList.newlyAddedCaseKeys);
            this.excuteAction({ value: caseList, action: 'edit' });
        } else {
            const key: string = this.typeaheadOptions.keyField;
            this.selectedItemKey = dataItem ? dataItem[key] : null;
            if (!this.modalOptions.multipick) {
                this.values = [...this.values, dataItem];
                this.onApply();
            }
        }
    }

    onAdd(): void {
        this.excuteAction({ value: null, action: 'add' });
        this.isAddAnotherChecked = false;
    }

    navigateTo(): void {
        this.modalRef.hide();
    }

    onSave(): void {
        const mode = this.isMaintenanceMode$.getValue();
        if (mode !== '' && this.componentRef) {
            switch (mode) {
                case 'add':
                case 'duplicate':
                case 'edit':
                    this.modalOptions.searchValue = this.storeSearchValue.getValue();
                    this.service.addOrUpdate$(this.typeaheadOptions.apiUrl, this.componentRef.instance.entry, this._addOrUpdateSuccess, this._addOrUpdateError);
                    break;
                case 'view':
                    break;
                default:
                    break;
            }
        }
    }

    onDelete(value: any): void {
        if (value && (value.key !== undefined && value.key !== null)) {
            this.service.delete$(this.typeaheadOptions.apiUrl, value.key, null, this._search);
        }
    }

    onApply(): void {
        if (this.values) {
            this.selectedRow$.next(this.values);
        }
        this.modalRef.hide();
        this.onClose$.next();
    }

    onClose(): void {
        const isMaintenance = this.isMaintenanceMode$.getValue();
        if (isMaintenance) {
            this._discard();
        } else {
            this.modalRef.hide();
        }
        this.modalOptions.searchValue = this.storeSearchValue.getValue();
        this.onClose$.next();
    }

    search(action?: NavigationEnum): void {
        this.storeSearchValue.next(this.picklistSearchField.model);
        this.searchResult.search({
            value: this.picklistSearchField.model,
            action: action || NavigationEnum.filtersChanged
        });
    }

    clear(): void {
        this.storeSearchValue.next('');
        this.values = [];
        this.searchResult.clear();
    }

    private readonly _addOrUpdateError = (errors: Array<{ field: string, error: string }>) => {
        if (errors && errors.length > 0) {
            errors.forEach((e) => {
                const errorObj = {};
                errorObj[e.error] = true;
                // tslint:disable-next-line: no-string-literal
                this.componentRef.instance.form.controls[e.field].markAsTouched();
                this.componentRef.instance.form.controls[e.field].markAsDirty();
                this.componentRef.instance.form.controls[e.field].setErrors(errorObj);
            });
        }
    };

    private readonly _addOrUpdateSuccess = () => {
        if (!this.canNavigate && this.modalOptions.isAddAnother && this.isAddAnotherChecked) {
            if (this.modalOptions.extendedParams) {
                this.excuteAction({ value: _.extend({}, this.modalOptions.extendedParams()), action: 'add' });
            } else {
                this.excuteAction({ value: null, action: 'add' });
            }

            this.updateModalState();

            return;
        }

        if (!this.canNavigate) {
            this.isMaintenanceMode$.next('');
            this.dynamicHost.viewContainerRef.clear();
        } else {
            this.updateModalState();
            this.notificationService.success();
            this.componentRef.instance.form.markAsPristine();
        }
        if (this.modalOptions.extendedParams) {
            const extendParams = this.modalOptions.extendedParams();
            if (extendParams && extendParams.callbackSuccess) {
                extendParams.callbackSuccess();
            }
        }
    };

    private readonly _search = (): void => {
        this.searchResult.gridOptions._search();
    };

    private readonly _discard = (): void => {
        if (this.componentRef.instance.form.dirty) {
            this.service.discard$(() => {
                this.dynamicHost.viewContainerRef.clear();
                this.isMaintenanceMode$.next('');
            });
        } else {
            this.dynamicHost.viewContainerRef.clear();
            this.isMaintenanceMode$.next('');
        }
    };

    private readonly switchTemplatesHookup = () => {
        this.isMaintenanceMode$.subscribe((value: string) => {
            this.configuredHeaderTemplate$.next(value !== '' ? this.maintenanceHeader : this.viewModeHeader);
            this.configuredNavigationHeader$.next(value !== '' ? this.navigationHeader : this.blankTemplate);

            switch (this.typeaheadOptions.picklistTemplateType) {
                case PicklistTemplateType.Valid:
                    this.configuredTemplate$.next(this.validTemplate);
                    break;
                case PicklistTemplateType.NameFiltered:
                    this.configuredTemplate$.next(this.nameFiltered);
                    break;
                case PicklistTemplateType.DesignationStage:
                    this.configuredTemplate$.next(this.designationStageTemplate);
                    break;
                case PicklistTemplateType.Name:
                    this.configuredTemplate$.next(this.name);
                    break;
                default:
                    this.configuredTemplate$.next(this.defaultTemplate);
                    break;
            }
        });
    };

    trackByFn = (index: number, item: any) => {
        return index;
    };

    showMoreInformation = (): boolean => {
        return this.typeaheadOptions.searchMoreInformation && this.typeaheadOptions.searchMoreInformation !== '';
    };
}
