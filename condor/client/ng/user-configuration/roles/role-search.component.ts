import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Hotkey } from 'angular2-hotkeys';
import { KeyBoardShortCutService } from 'core/keyboardshortcut.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject } from 'rxjs';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { RoleSearchService, RoleSearchState } from './role-search.service';
import { RoleSearchMaintenanceComponent } from './roles-details-maintenance/role-search-maintenance.component';
import { ObjectTable, PermissionType, PermissionTypeText } from './roles.model';

@Component({
    selector: 'role-search',
    templateUrl: './role-search.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class RoleSearchComponent implements OnInit {
    @Input() viewData: any;
    formData: any;
    permission: Array<any> = [];
    gridOptions: IpxGridOptions;
    roleSearch: any = {};
    searchName: string;
    queryContextKeyEnum: queryContextKeyEnum;
    actions: Array<IpxBulkActionOptions>;
    _resultsGrid: IpxKendoGridComponent;
    roleSearchState = RoleSearchState;
    bsModalRef: BsModalRef;
    isRolesLoaded = new BehaviorSubject<boolean>(false);
    callOnsaveRoles = false;
    @ViewChild('configurationForm', { static: true }) configurationForm: NgForm;
    @ViewChild('roleSearchGrid', { static: true }) roleSearchGrid: IpxKendoGridComponent;
    @ViewChild('roleSearchGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }

    constructor(private readonly roleSearchService: RoleSearchService,
        private readonly cdRef: ChangeDetectorRef, private readonly stateService: StateService,
        private readonly keyBoardShortCutService: KeyBoardShortCutService,
        private readonly notificationService: NotificationService,
        private readonly translate: TranslateService,
        private readonly modalService: IpxModalService) {
        this.initShortcuts();
    }

    initFormData(resetForm = false): void {
        this.formData = {
            roleId: '',
            roleName: '',
            roleDescription: '',
            isExternal: true,
            isInternal: true,
            task: { Picklist: null, permissions: '', execute: false, update: false, insert: false, delete: false },
            webPart: { Picklist: null, permissions: '', access: false, mandatory: false },
            subject: { Picklist: null, permissions: '', access: false }
        };
        const previousState = this.roleSearchService._previousStateParam$.getValue();
        if (previousState && !resetForm) {
            this.formData = previousState.formData;
            setTimeout(() => {
                this.search();
                this.roleSearchService._previousStateParam$.next(null);
            }, 500);
        }
    }

    initShortcuts = () => {
        const hotkeys = [
            new Hotkey(
                'enter',
                (event, combo): boolean => {
                    this.search();

                    return true;
                }, null, 'shortcuts.search', undefined, false)
        ];
        this.keyBoardShortCutService.add(hotkeys);
    };

    toggleInternal(event, controlId: number): void {
        if (!this.formData.isInternal || !this.formData.isExternal) {
            controlId === 0 ? this.formData.isExternal = true : this.formData.isInternal = true;
        }
        this.cdRef.markForCheck();
    }

    onChangeTask(): void {
        if (this.formData.task.permissions !== '' && this.formData.task.Picklist) {
            this.formData.task.execute = this.formData.task.Picklist.executePermission;
            this.formData.task.update = this.formData.task.Picklist.updatePermission;
            this.formData.task.insert = this.formData.task.Picklist.insertPermission;
            this.formData.task.delete = this.formData.task.Picklist.deletePermission;
        } else {
            this.formData.task.execute = false;
            this.formData.task.update = false;
            this.formData.task.insert = false;
            this.formData.task.delete = false;
        }
    }

    onChangeWebpart(): void {
        if (this.formData.webPart.permissions !== '' && this.formData.webPart.Picklist) {
            this.formData.webPart.access = true;
            this.formData.webPart.mandatory = true;
        } else {
            this.formData.webPart.access = false;
            this.formData.webPart.mandatory = false;
        }
    }

    onChangeSubject(): void {
        this.formData.subject.access = (this.formData.subject.permissions !== '' && this.formData.subject.Picklist) ? true : false;
    }

    ngOnInit(): void {
        this.initFormData();
        this.actions = this.initializeMenuActions();
        this.gridOptions = this.buildGridOptions();
        this.permission = [{ id: PermissionType.Granted, name: PermissionTypeText.Granted }, { id: PermissionType.Denied, name: PermissionTypeText.Denied }, { id: PermissionType.NotAssigned, name: PermissionTypeText.NotAssigned }];
    }

    initSearch = (): void => {
        this.roleSearchService.inUseRoles = [];
        this.roleSearch = {};
        this.roleSearch.roleName = this.formData.roleName;
        this.roleSearch.description = this.formData.roleDescription;
        this.roleSearch.isExternal = (this.formData.isInternal && this.formData.isExternal) ? null : this.formData.isInternal ? 0 : 1;
        this.roleSearch.permissionsGroup = { permissions: [] };
        if (this.formData.task.Picklist && this.formData.task.permissions) {
            this.roleSearch.permissionsGroup.permissions.push({
                objectTable: ObjectTable.TASK,
                objectIntegerKey: this.formData.task.Picklist.key,
                permissionType: this.formData.task.permissions,
                permissionLevel: {
                    canExecute: this.formData.task.execute, canUpdate: this.formData.task.update,
                    canInsert: this.formData.task.insert, canDelete: this.formData.task.delete
                }
            });
        }
        if (this.formData.webPart.Picklist && this.formData.webPart.permissions) {
            this.roleSearch.permissionsGroup.permissions.push({
                objectTable: ObjectTable.MODULE,
                objectIntegerKey: this.formData.webPart.Picklist.key,
                permissionType: this.formData.webPart.permissions,
                permissionLevel: {
                    canSelect: this.formData.webPart.access, isMandatory: this.formData.webPart.mandatory
                }
            });
        }
        if (this.formData.subject.Picklist && this.formData.subject.permissions) {
            this.roleSearch.permissionsGroup.permissions.push({
                objectTable: ObjectTable.DATATOPIC,
                objectIntegerKey: this.formData.subject.Picklist.key,
                permissionType: this.formData.subject.permissions,
                permissionLevel: {
                    canSelect: this.formData.subject.access
                }
            });
        }
    };

    search = (): void => {
        this.initSearch();
        this.gridOptions._search();
    };

    clear(): void {
        this.roleSearchService.inUseRoles = [];
        this.initFormData(true);
        this.roleSearchGrid.clear();
        this.cdRef.markForCheck();
    }
    subscribeRowSelectionChange = () => {
        this._resultsGrid.rowSelectionChanged.subscribe((event) => {
            const anySelected = event.rowSelection.length > 0;
            const deleteAll = this.actions.find(x => x.id === 'deleteAll');
            if (deleteAll) {
                deleteAll.enabled = anySelected && this.viewData.canDeleteRole;
            }
            const duplicate = this.actions.find(x => x.id === 'duplicate');
            if (duplicate) {
                duplicate.enabled = event.rowSelection.length === 1 && this.viewData.canCreateRole;
            }
        });
    };
    anySelectedSubject = new BehaviorSubject<boolean>(false);
    private initializeMenuActions(): Array<IpxBulkActionOptions> {
        const menuItems: Array<IpxBulkActionOptions> = [{
            ...new IpxBulkActionOptions(),
            id: 'deleteAll',
            icon: 'cpa-icon cpa-icon-trash',
            text: 'roleSearch.delete',
            enabled: false,
            click: () => {
                this.notificationService.confirmDelete({
                    message: 'modal.confirmDelete.message'
                }).then(() => {
                    this.deleteSelectedRoles();
                });
            }
        }, {
            ...new IpxBulkActionOptions(),
            id: 'duplicate',
            icon: 'cpa-icon cpa-icon-plus-stack-square-o',
            text: 'roleSearch.duplicate',
            enabled: false,
            click: this.duplicateRole
        }];

        return menuItems;
    }

    resetSelection = () => {
        this.roleSearchService.inUseRoles = [];
        this.roleSearchGrid.resetSelection();
    };

    deleteSelectedRoles = () => {
        const selections = this.roleSearchGrid.getSelectedItems('roleId');
        this.roleSearchService.deleteroles(selections).subscribe((response: any) => {
            this.resetSelection();
            if (response.hasError) {
                const allInUse = selections.length === response.inUseIds.length;
                const message = allInUse ? this.translate.instant('roleDetails.alert.alreadyInUse')
                    : this.translate.instant('modal.alert.partialComplete') + '<br/>' + this.translate.instant('roleDetails.alert.alreadyInUse');
                const title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';
                this.roleSearchService.inUseRoles = this.roleSearchService.inUseRoles
                    .concat(response.inUseIds);
                this.notificationService.alert({
                    title,
                    message
                });
                this.gridOptions._search();
            } else {
                this.notificationService.success();
                this.gridOptions._search();
            }
        });
    };

    duplicateRole = () => {
        const selections = this.roleSearchGrid.getSelectedItems('roleId');
        this.openModal(this.dataItemByRoleId(selections[0]), this.roleSearchState.DuplicateRole);
    };

    openModal = (dataItem: any, state: string) => {
        const initialState = {
            displayNavigation: state === 'updating' ? true : false,
            states: state,
            dataItem
        };
        this.bsModalRef = this.modalService.openModal(RoleSearchMaintenanceComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState
        });
        this.bsModalRef.content.searchRecord.subscribe(
            (callbackParams: any) => {
                this.bsModalRef.hide();
                if (callbackParams.roleId) {
                    this.callOnsaveRoles = true;
                    this.isRolesLoaded.subscribe(result => {
                        if (result) {
                            let roleDataItem = this.dataItemByRoleId(callbackParams.roleId);
                            if (!roleDataItem) {
                                roleDataItem = { roleId: callbackParams.roleId, rowKey: -1 };
                            }
                            this.openRoleDetails(roleDataItem);
                        }
                    });
                    this.search();
                }
            }
        );
    };

    dataItemByRoleId(roleId: number): any {
        const data: any = this._resultsGrid.wrapper.data;
        const dataItem = _.first(data.filter(d => d.roleId === roleId));

        return dataItem;
    }

    private buildGridOptions(): IpxGridOptions {
        this.roleSearchGrid.rowSelectionChanged.subscribe((event) => {
            const anySelected = event.rowSelection.length > 0;
            this.anySelectedSubject.next(anySelected);
        });

        return {
            sortable: true,
            autobind: false,
            selectable: {
                mode: 'multiple'
            },
            onDataBound: (data: any) => {
                this.roleSearchGrid.resetSelection();
                this.roleSearchService.markInUseRoles(data);
                if (this.callOnsaveRoles) {
                    this.callOnsaveRoles = false;
                    this.isRolesLoaded.next(true);
                }
            },
            customRowClass: (context) => {
                if (context.dataItem.inUse) {
                    return ' error';
                }

                return '';
            },
            bulkActions: this.actions,
            read$: (queryParams) => {
                return this.roleSearchService.runSearch(this.roleSearch, queryParams);
            },
            columns: [{
                field: 'roleName', title: 'roleSearch.roleName', width: 250, sortable: true, template: true
            }, {
                field: 'description', title: 'roleSearch.roleDescription', sortable: true
            }, {
                field: 'isExternal', title: 'roleSearch.external',
                defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true, sortable: true
            }, {
                field: 'isInternal', title: 'roleSearch.internal',
                defaultColumnTemplate: DefaultColumnTemplateType.selection, disabled: true, sortable: true
            }],
            selectedRecords: {
                rows: {
                    rowKeyField: 'roleId',
                    selectedKeys: []
                }
            }
        };
    }

    openRoleDetails = (dataItem: any): void => {
        if (!dataItem.roleId) { return; }
        this.roleSearchService._previousStateParam$.next({ formData: this.formData });
        this.stateService.go('role-details', {
            id: dataItem.roleId,
            rowKey: dataItem.rowKey
        }, { inherit: false });
    };
}
