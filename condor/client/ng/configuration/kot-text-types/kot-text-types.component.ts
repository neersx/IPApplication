import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { Transition } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Subscription } from 'rxjs';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { KotMaintainConfigComponent } from './kot-maintain-config/kot-maintain-config.component';
import { KotFilterCriteria, KotFilterTypeEnum, KotPermissionsType } from './kot-text-types.model';
import { KotTextTypesService } from './kot-text-types.service';

@Component({
    selector: 'kot-text-types',
    templateUrl: './kot-text-types.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})

export class KotTextTypesComponent implements OnInit, OnDestroy {
    @Input() viewData: KotPermissionsType;
    gridOptions: IpxGridOptions;
    filterBy: KotFilterTypeEnum;
    addedRecordId: number;
    deleteSubscription: Subscription;
    get KotFilterTypeEnum(): typeof KotFilterTypeEnum {
        return KotFilterTypeEnum;
    }
    roles: any;
    modules: any;
    status: any;
    filterCriteria: KotFilterCriteria;
    showSearchBar = true;

    constructor(private readonly service: KotTextTypesService,
        private readonly trans: Transition, private readonly modalService: IpxModalService,
        private readonly notificationService: NotificationService) {
    }
    ngOnDestroy(): void {
        if (!!this.deleteSubscription) {
            this.deleteSubscription.unsubscribe();
        }
    }

    ngOnInit(): void {
        this.filterCriteria = new KotFilterCriteria();
        this.filterBy = this.trans.params().isCaseType ? KotFilterTypeEnum.byCase : KotFilterTypeEnum.byName;
        this.filterCriteria.type = this.filterBy;
        this.gridOptions = this.buildGridOptions();
    }

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            pageable: true,
            navigable: true,
            sortable: true,
            reorderable: true,
            showExpandCollapse: true,
            showGridMessagesUsingInlineAlert: false,
            enableGridAdd: true,
            rowMaintenance: {
                canDelete: true,
                canEdit: true,
                canDuplicate: true
            },
            read$: (queryParams) => {

                return this.service.getKotTextTypes(this.filterCriteria, queryParams);
            },
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && context.dataItem.id === this.addedRecordId) {
                    returnValue += ' saved k-state-selected selected';
                }

                return returnValue;
            },
            columns: this.getColumns()
        };
    }

    setBackgroundColor = (type: string): any => {

        return {
            'background-color': type === null ? '#ffff' : type,
            display: 'block'
        };
    };

    changeFilterBy = (event: any) => {
        this.filterCriteria.type = event;
        this.filterBy = event;
        this.clear();
        this.gridOptions.columns[0].title = this.getColumnType().title;
        this.gridOptions.columns[0].field = this.getColumnType().field;
        this.gridOptions.columns[4].hidden = this.filterBy === KotFilterTypeEnum.byName;
        this.gridOptions._search();
    };

    private readonly getColumnType = (): any => {
        const columnType = {
            title: this.filterCriteria.type === KotFilterTypeEnum.byCase ? 'kotTextTypes.column.caseType' : 'kotTextTypes.column.nameType',
            field: this.filterCriteria.type === KotFilterTypeEnum.byCase ? 'caseTypes' : 'nameTypes'
        };

        return columnType;
    };

    search(): void {
        this.createFilterCriteria();
        this.gridOptions._search();
    }

    clear(): void {
        this.modules = null;
        this.status = null;
        this.roles = null;
        this.createFilterCriteria();
        this.gridOptions._search();
    }

    createFilterCriteria(): void {
        this.filterCriteria.modules = this.modules ? this.modules.map(x => x.name) : null;
        this.filterCriteria.statuses = this.status ? this.status.map(x => x.name) : null;
        this.filterCriteria.roles = this.roles ? this.roles.map(x => x.value) : null;
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: this.getColumnType().title,
            field: this.getColumnType().field,
            sortable: false
        }, {
            title: 'kotTextTypes.column.textType',
            field: 'textType',
            sortable: true
        }, {
            title: 'kotTextTypes.column.roles',
            field: 'roles',
            sortable: false
        }, {
            title: 'kotTextTypes.column.modules',
            field: 'modules',
            sortable: false
        }, {
            title: 'kotTextTypes.column.statusSummary',
            field: 'statusSummary',
            sortable: false,
            hidden: this.filterBy === KotFilterTypeEnum.byName
        }, {
            title: 'kotTextTypes.column.backgroundColor',
            field: 'backgroundColor',
            sortable: false,
            template: true
        }];

        return columns;
    };

    onRowAddedOrEdited(data: any, state: string): void {
        const modal = this.modalService.openModal(KotMaintainConfigComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                state,
                entryId: data && data.dataItem ? data.dataItem.id : null,
                filterBy: this.filterBy
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event);
            }
        );

        modal.content.addedRecordId$.subscribe(
            (event: any) => {
                this.addedRecordId = event;
            }
        );
    }

    onCloseModal(event): void {
        if (event) {
            this.notificationService.success();
            this.gridOptions._search();
        }
    }

    onRowDeleted(data: any): void {
        this.notificationService.confirmDelete({
            message: 'picklistmodal.confirm.delete'
        }).then(() => {
            if (data) {
                this.deleteKot(data.id);
            }
        });
    }

    deleteKot(id: number): void {
        this.deleteSubscription = this.service.deleteKotTextType(id, this.filterBy).subscribe((response: any) => {
            if (response) {
                if (response.result === 'success') {
                    this.gridOptions._search();
                }
            }
        });
    }
}