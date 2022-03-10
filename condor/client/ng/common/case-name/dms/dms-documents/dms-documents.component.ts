import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ContentChildren, EventEmitter, Input, OnChanges, OnInit, Output, QueryList, SimpleChanges, TemplateRef, ViewChild, ViewChildren } from '@angular/core';
import { DomSanitizer, SafeUrl } from '@angular/platform-browser';
import { LocalSettings } from 'core/local-settings';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { DmsViewData } from '../dms-view-data';
import { DmsService } from '../dms.service';
import { selectedDocument } from '../dms.types';

@Component({
    selector: 'dms-documents',
    templateUrl: './dms-documents.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    styles: ['.txt-area { width:80%; margin-left:10px; vertical-align: top;}']
})
export class DmsDocumentComponent implements OnInit, OnChanges, AfterViewInit {
    @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
    @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
    @ViewChildren(TemplateRef) templates: QueryList<TemplateRef<any>>;
    @Input() callerType: 'CaseView' | 'NameView';
    @Input() selectedId: {
        siteDbId: number,
        containerId: string,
        folderType: 'folder' | 'emailFolder',
        canHaveRelatedDocuments: boolean
    };
    @Output() readonly onDocumentSelected = new EventEmitter<selectedDocument>();
    gridOptions: IpxGridOptions;
    detailColumns: Array<any>;
    @Input() dmsViewData: DmsViewData;
    docTypeIconMap = {
        ['doc']: 'file-word-o',
        ['docx']: 'file-word-o',
        ['pdf']: 'file-pdf-o',
        ['txt']: 'file-o',
        ['xlsx']: 'file-excel-o',
        ['jpg']: 'file-image-o',
        ['msg']: 'envelope'
    };

    selectedRelateDocumentId: any;

    constructor(private readonly service: DmsService, private readonly cdr: ChangeDetectorRef, private readonly sanitizer: DomSanitizer, readonly localSettings: LocalSettings) {
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
    }

    ngAfterViewInit(): void {
        if (this.selectedId && this.gridOptions) {
            this.gridOptions._search();
        }
    }

    ngOnChanges(changes: SimpleChanges): void {
        if (changes.selectedId && changes.selectedId.currentValue && this.gridOptions) {
            this.rebuildColumns();
            this.grid.getCurrentData().forEach((d, index) => {
                const idx = this.grid.wrapper.skip !== 0 ? (index - this.grid.wrapper.skip) : index;
                this.grid.wrapper.collapseRow(idx);
            });
            this.gridOptions._search();
            this.cdr.markForCheck();
        }
    }

    private readonly buildGridOptions = (): IpxGridOptions => {
        let pageSize: number;
        const pageSizeSetting = this.localSettings.keys.caseView.documentManagement.pageSize;
        if (pageSizeSetting) {
            pageSize = pageSizeSetting.getLocal;
        }
        const options: IpxGridOptions = {
            sortable: false,
            showGridMessagesUsingInlineAlert: true,
            autobind: false,
            reorderable: false,
            pageable: { pageSizeSetting, pageSizes: [10, 20, 50] },
            enableGridAdd: false,
            selectable: {
                mode: 'single'
            },
            gridMessages: {
                noResultsFound: 'grid.messages.noItems',
                performSearch: 'caseview.caseDocumentManagementSystem.selectFolder'
            },
            read$: (queryParams) => {
                return this.service.getDmsDocuments$(this.selectedId.siteDbId, this.selectedId.containerId, queryParams, this.selectedId.folderType);
            },
            detailTemplate: this.detailTemplate,
            columns: this.getColumns(this.selectedId.folderType || 'folder')
        };

        return options;
    };
    sanitize(url: string): SafeUrl {
        return this.sanitizer.bypassSecurityTrustUrl(url);
    }

    onPageChanged(): void {
        this.grid.collapseAll();
    }

    onSelectRelatedDocuments = (dataItem: any): void => {
        this.selectedRelateDocumentId = dataItem.id;
        this.documentSelected(dataItem);
    };

    private readonly rebuildColumns = () => {
        this.detailColumns = this.getColumns(this.selectedId.folderType);
        this.grid.resetColumns(this.detailColumns);
    };
    expandRow = (event: any) => {
        if (event && event.dataItem && event.expand === true) {
            if (event.dataItem.relatedDocuments.length === 0 && !event.dataItem.profileLoaded) {
                event.dataItem.detailLoading = true;
                this.service.getDmsDocumentDetails$(event.dataItem.siteDbId, event.dataItem.containerId).subscribe(data => {
                    const gridData = this.grid.getCurrentData();
                    const index = this.grid.wrapper.skip !== 0 ? (event.index - this.grid.wrapper.skip) : event.index;
                    gridData[index].relatedDocuments = data.relatedDocuments;
                    gridData[index].comment = data.comment;
                    event.dataItem.detailLoading = false;
                    this.cdr.markForCheck();
                    this.grid.wrapper.expandRow(index);
                }, (error) => {
                    event.dataItem.detailLoading = false;
                    this.cdr.markForCheck();
                });
            } else {
                this.grid.wrapper.expandRow(event.index);
            }
        }
    };
    private readonly getColumns = (type: string): Array<GridColumnDefinition> => {
        switch (type) {
            case 'folder': return this.getDefaultColumns();
            case 'emailFolder': return this.getEmailFolderColumns();
            default:
                return this.getDefaultColumns();
        }
    };
    private readonly getDefaultColumns = (): Array<GridColumnDefinition> => {

        return [
            this.columns.applicationExtension,
            this.columns.hasAttachments,
            this.columns.description,
            this.columns.version,
            this.columns.authorFullName,
            this.columns.docTypeDescription,
            this.columns.dateEdited,
            this.columns.dateCreated,
            this.columns.size,
            this.columns.docNumber
        ];
    };

    private readonly getEmailFolderColumns = (): Array<GridColumnDefinition> => {

        return [
            this.columns.applicationExtension,
            this.columns.hasAttachments,
            this.columns.emailFrom,
            this.columns.emailTo,
            this.columns.description,
            this.columns.emailDateReceived,
            this.columns.dateCreated,
            this.columns.size,
            this.columns.docNumber
        ];
    };
    private readonly columns = {
        applicationExtension: {
            title: 'Type',
            field: 'applicationExtension',
            template: true,
            sortable: false,
            width: 30
        }, hasAttachments: {
            title: '',
            iconName: 'paperclip',
            field: 'hasAttachments',
            template: true,
            sortable: false
        }, emailFrom: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.from',
            field: 'emailFrom',
            template: true,
            sortable: false
        }, emailTo: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.to',
            field: 'emailTo',
            template: true,
            sortable: false
        }, description: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.description',
            field: 'description',
            sortable: false,
            template: true,
            width: 300
        }, emailDateReceived: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.emailDateReceived',
            field: 'emailDateReceived',
            template: true,
            sortable: false
        }, version: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.version',
            template: false,
            field: 'version',
            sortable: false
        }, authorFullName: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.staffMember',
            field: 'authorFullName',
            sortable: false
        }, docTypeDescription: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.docType',
            field: 'docTypeDescription',
            sortable: false,
            width: 100
        }, dateEdited: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.dateEdited',
            field: 'dateEdited',
            template: true,
            sortable: false,
            width: 150
        }, dateCreated: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.dateCreated',
            field: 'dateCreated',
            template: true,
            sortable: false,
            width: 150
        }, size: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.size',
            field: 'size',
            template: true,
            sortable: false,
            width: 70
        }, docNumber: {
            title: 'caseview.caseDocumentManagementSystem.documentColumns.docNumber',
            field: 'id',
            defaultColumnTemplate: DefaultColumnTemplateType.number,
            sortable: false
        }
    };

    documentSelected = (item) => {
        const link = item.iwl;
        this.onDocumentSelected.emit({ link, description: item.description });
    };
}