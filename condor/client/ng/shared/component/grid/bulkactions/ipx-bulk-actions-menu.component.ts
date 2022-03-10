import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Host, Input, OnInit, Renderer2, ViewChild } from '@angular/core';
import { GridDataResult } from '@progress/kendo-angular-grid';
import { IpxKendoGridComponent, scrollableMode } from '../ipx-kendo-grid.component';
import { IpxBulkActionOptions } from './ipx-bulk-actions-options';

@Component({
    selector: 'ipx-bulk-actions-menu',
    templateUrl: './ipx-bulk-actions-menu.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class BulkActionsMenuComponent implements OnInit, AfterViewInit {
    @Input() actionItems: Array<IpxBulkActionOptions>;
    @Input() isScroll = false;
    isOpen = false;
    isSelectAllEnable: boolean;
    @ViewChild('ddMenu') ddMenu: ElementRef;
    @ViewChild('bulkButton', { static: false }) bulkButton: ElementRef;

    paging = {
        available: true
    };
    items = {
        selected: 0,
        totalCount: 0
    };
    isSelectPage = false;
    context = 'a123';

    constructor(private readonly element: ElementRef, private readonly renderer: Renderer2, @Host() private readonly grid: IpxKendoGridComponent, private readonly cdr: ChangeDetectorRef) {

    }

    ngOnInit(): void {
        const elm = this.element.nativeElement;
        const th = this.closest(elm, node => node.tagName === 'TH');
        const headerWrap = this.closest(th, node => this.hasClasses(node, 'k-grid-header'));

        this.renderer.setStyle(th, 'overflow', 'visible');
        this.renderer.setStyle(headerWrap, 'overflow', 'visible');
    }

    ngAfterViewInit(): void {
        this.grid.dataOptions.persistSelection = !!this.grid.dataOptions.pageable || (this.grid.dataOptions.persistSelection && this.grid.dataOptions.scrollableOptions.mode === scrollableMode.virtual);
        this.grid.rowSelectionChanged.subscribe((event: { rowSelection: Array<any>, selectedRows: Array<any>, nonPagingRecordCount?: number, totalRecord?: number, allDeSelectIds?: Array<any> }) => {
            if (event.selectedRows) {
                this.items.selected = event.rowSelection.length > 0 ? event.rowSelection.length : event.selectedRows.length;
                this.setSelectAll(event.rowSelection, event.totalRecord, event.allDeSelectIds ? event.allDeSelectIds : []);
            } else {
                this.items.selected = event.nonPagingRecordCount !== undefined && event.nonPagingRecordCount !== null ? event.nonPagingRecordCount : event.rowSelection.length;
                this.setDeSelectAll(event.totalRecord, event.allDeSelectIds);
            }

            this.cdr.markForCheck();
        });

        this.grid.totalRecord.subscribe((event) => {
            this.isSelectAllEnable = event === 0 ? true : false;
            const exportExcel = this.actionItems.find(x => x.id === 'case-export-excel');
            if (exportExcel) {
                exportExcel.enabled = !this.isSelectAllEnable;
            }
            const cpaXML = this.actionItems.find(x => x.id === 'case-cpa-xml-import');
            if (cpaXML) {
                cpaXML.enabled = !this.isSelectAllEnable;
            }
            if (this.items.selected === 0) {
                this.isSelectPage = false;
            }
        });
        this.actionItems.forEach(action => {
            if (action.enabled$) {
                action.enabled$.subscribe(enabled => {
                    action.enabled = enabled;
                });
            }
            if (action.enabled === 'single-selection') {
                this.grid.getRowSelectionParams().singleRowSelected$.subscribe(enabled => {
                    action.enabled = enabled;
                });
            }
            if (action.text$) {
                action.text$.subscribe(text => {
                    action.text = text;
                });
            }
        });
        this.grid.dataBound.subscribe(() => {
            if (!this.grid.dataOptions.persistSelection) {
                this.items.selected = 0;
                this.clearSelection();
                this.isSelectPage = false;
            }
            this.cdr.markForCheck();
        });
    }

    setSelectAll(selectedRows: Array<any>, totalRecord?: number, allDeSelectIds?: Array<any>): void {
        if (selectedRows.length === totalRecord) {
            this.isSelectPage = true;
        }
        if (selectedRows.length === 0 && (allDeSelectIds || allDeSelectIds.length !== 0)) {
            if (allDeSelectIds.length === totalRecord) {
                this.isSelectPage = false;
            }
        }
    }

    setDeSelectAll(totalRecord?: number, allDeSelectIds?: Array<any>): void {
        if (allDeSelectIds.length === totalRecord) {
            this.isSelectPage = false;
        }
    }

    onClick(): void {
        if (this.isScroll) {
            const top = this.bulkButton.nativeElement.getBoundingClientRect().top + 18;
            const left = this.bulkButton.nativeElement.getBoundingClientRect().left + 25;
            this.ddMenu.nativeElement.style.position = 'fixed';
            this.ddMenu.nativeElement.style.top = top + 'px';
            this.ddMenu.nativeElement.style.left = left + 'px';
        }
        this.isOpen = !this.isOpen;
        if (this.isOpen) {
            const firstA = this.ddMenu.nativeElement.querySelector('ul li a');
            if (firstA) {
                firstA.focus();
            }
        }
    }

    hide(): void {
        this.isOpen = false;
    }

    selectAllPage(event): void {
        if (!this.isSelectAllEnable) {
            event.stopPropagation();
            if (this.isSelectPage) {
                this.clearSelection();

                return;
            }
            this.grid.selectAllPage();
            this.isSelectPage = true;
        }
    }

    doClear(event): void {
        event.stopPropagation();
        this.clearSelection();
    }

    clearSelection(): void {
        this.isSelectPage = false;
        this.grid.clearSelection();
    }

    isAllSelected(): boolean {
        return false;
    }

    isClearDisabled(): boolean {
        return this.items.selected === 0;
    }

    hasItemsSelected(): boolean {
        return this.items.selected > 0;
    }

    trackByFn = (index: number, action: IpxBulkActionOptions): string => {
        return action.id;
    };

    invokeIfEnabled = (action: IpxBulkActionOptions) => {
        if (action.enabled) {
            this.hide();
            action.click(this.grid);
        }
    };

    private readonly closest = (node, predicate) => {
        while (node && !predicate(node)) {
            // tslint:disable-next-line: no-parameter-reassignment
            node = node.parentNode;
        }

        return node;
    };

    private readonly hasClasses = (element: HTMLElement, classNames: string): boolean => {
        const namesList = this.toClassList(classNames);

        return Boolean(this.toClassList(element.className).find((className) => namesList.indexOf(className) >= 0));
    };

    private readonly toClassList = (classNames: string) => String(classNames).trim().split(' ');
}