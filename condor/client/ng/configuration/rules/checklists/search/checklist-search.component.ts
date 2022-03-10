import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { LocalSettings } from 'core/local-settings';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { ChecklistConfigurationViewData } from '../checklists.models';
import { CreateChecklistComponent } from '../maintenance/create-checklist/create-checklist.component';
import { ChecklistSearchService } from './checklist-search.service';
import { SearchByCaseComponent } from './search-by-case/search-by-case.component';
import { SearchByCharacteristicComponent } from './search-by-characteristics/search-by-characteristic.component';

@Component({
    selector: 'ipx-checklist-search',
    templateUrl: './checklist-search.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})
export class ChecklistSearchComponent implements OnInit, AfterViewInit {
    @Input() viewData: ChecklistConfigurationViewData;
    @ViewChild('searchResultsGrid', { static: true }) searchResultsGrid: IpxKendoGridComponent;
    @ViewChild('criteriaDetailsTemplate', { static: true }) criteriaDetailsTemplate: any;
    @ViewChild('inheritedDetailsTemplate', { static: true }) inheritedDetailsTemplate: any;
    @ViewChild('searchByCharacteristics', { static: true }) searchByCharacteristics: SearchByCharacteristicComponent;
    @ViewChild('searchByCase', { static: true }) searchByCase: SearchByCaseComponent;
    showSearchBar = true;
    matchType: string;
    criteria: any;
    queryParams: any;
    searchGridOptions: IpxGridOptions;
    canCreateNewChecklist: boolean | false;
    itemName: string;

    constructor(private readonly cdRef: ChangeDetectorRef, public searchService: ChecklistSearchService, private readonly localSettings: LocalSettings,
            private readonly translateService: TranslateService, private readonly modalService: IpxModalService) {
        this.itemName = this.translateService.instant('Checklist');
    }

    ngOnInit(): void {
        this.canCreateNewChecklist = this.viewData.canAddRules || this.viewData.canAddProtectedRules;
        this.initGridOption();
        this.cdRef.detectChanges();
    }

    ngAfterViewInit(): void {
        this.matchType = 'characteristic';
    }

    search(value: any): void {
        this.criteria = value;
        this.searchResultsGrid.dataOptions.gridMessages.noResultsFound = (value.matchType === 'exact-match' || !!value.checklist ? 'noResultsFound' : 'checklistConfiguration.search.noResultsHintBestCriteriaAndMatch');
        this.searchResultsGrid.search();
    }

    clear(): void {

        return;
    }

    submitForm(): void {

        return;
    }

    addNewChecklist(): void {
        let criteria = {};
        if (this.matchType === 'characteristic') {
            criteria = this.searchByCharacteristics.formData;
        }
        if (this.matchType === 'case') {
            criteria = this.searchByCase.formData;
        }
        const createChecklistRef = this.modalService.openModal(CreateChecklistComponent, {
            animated: false,
            ignoreBackdropClick: true,
            class: 'modal-xl',
            initialState: { hasOffices: this.viewData.hasOffices, canAddProtectedRules: this.viewData.canAddProtectedRules, canAddRules: this.viewData.canAddRules, criteria }
        });
        createChecklistRef.content.success$
            .subscribe((response: boolean) => {
                if (!!response) {
                    this.search(criteria);
                }
            });
    }

    initGridOption(): void {
        this.searchGridOptions = {
            filterable: false,
            navigable: true,
            sortable: true,
            autobind: false,
            reorderable: true,
            selectable: true,
            pageable: {
                pageSize: 10,
                pageSizes: [10, 20, 50, 100, 250]
            },
            columnSelection: {
                localSetting: this.localSettings.keys.checklistSearch.search.columnsSelection
            },
            read$: (queryParams: any) => {
                this.queryParams = queryParams;

                return this.searchService.search$(this.matchType, this.criteria, queryParams);
            },
            columns: [{
                title: '',
                sortable: false,
                field: 'isInherited',
                width: 28,
                fixed: true,
                template: this.inheritedDetailsTemplate
            }, {
                title: '',
                sortable: false,
                field: 'isProtected',
                width: 28,
                fixed: true,
                defaultColumnTemplate: DefaultColumnTemplateType.protected
            }, {
                title: 'Criteria No.',
                field: 'id',
                width: 110,
                fixed: true,
                template: this.criteriaDetailsTemplate
            }, {
                title: 'Criteria Name',
                field: 'criteriaName',
                width: 200
            }, {
                title: 'Checklist Type',
                field: 'checklistType',
                width: 150,
                filter: true,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'Office',
                field: 'office',
                width: 120,
                hidden: !this.viewData.hasOffices,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'Case Type',
                field: 'caseType',
                width: 200,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'Jurisdiction',
                field: 'jurisdiction',
                width: 150,
                filter: true,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'propertyType',
                field: 'propertyType',
                width: 150,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'Case Category',
                field: 'caseCategory',
                width: 200,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'Sub Type',
                field: 'subType',
                width: 200,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'Basis',
                field: 'basis',
                width: 200,
                defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
            }, {
                title: 'In Use',
                field: 'inUse',
                width: 100,
                defaultColumnTemplate: DefaultColumnTemplateType.selection,
                disabled: true
            }, {
                title: 'Local Client',
                field: 'isLocalClient',
                width: 100,
                defaultColumnTemplate: DefaultColumnTemplateType.selection,
                disabled: true
            }]
        };
    }

}
