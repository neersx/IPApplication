import { ChangeDetectionStrategy, Component, ElementRef, EventEmitter, HostBinding, Input, NgZone, OnDestroy, OnInit, Output, Renderer2 } from '@angular/core';

@Component({
    selector: 'ipx-grid-column-list',
    templateUrl: './ipx-grid-column-list.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxGridColumnListComponent implements OnInit, OnDestroy {

    // tslint:disable-next-line: no-output-native
    @Output() readonly reset: EventEmitter<any> = new EventEmitter<any>();

    @Output() readonly columnChange: EventEmitter<any> = new EventEmitter<any>();

    // tslint:disable-next-line: prefer-inline-decorator
    @Input()
    set columns(value: Array<any>) {
        this._columns = value.filter(column => column.includeInChooser !== false);
        this.allColumns = value;
        this.total = this._columns.length;
        this.selected = this._columns.filter(c => c.hidden !== true).length;
        this.updateColumnState();
    }
    get columns(): Array<any> {
        return this._columns;
    }

    @Input() readonly originalColumns: Array<any>;

    private hasLocked: boolean;
    private hasVisibleLocked: boolean;
    private unlockedCount = 0;
    private hasUnlockedFiltered: boolean;
    private hasFiltered: boolean;
    private _columns: Array<any>;
    private allColumns: Array<any>;
    private domSubscriptions: any;
    total: number;
    selected: number;

    constructor(private readonly element: ElementRef, private readonly ngZone: NgZone, private readonly renderer: Renderer2) {
    }

    isDisabled(column: any): boolean {
        return !(this.hasFiltered || column.hidden || this.columns.find(current => current !== column && !current.hidden)) ||
            (this.hasVisibleLocked && !this.hasUnlockedFiltered && this.unlockedCount === 1 && !column.locked && !column.hidden);
    }

    ngOnInit(): void {
        if (!this.element) {
            return;
        }
        this.ngZone.runOutsideAngular(() => {
            this.domSubscriptions = this.renderer.listen(this.element.nativeElement, 'click', (e) => {
                if (this.hasClasses(e.target, 'k-checkbox-column-picker')) {
                    const checkbox = e.target.previousSibling;
                    if (checkbox.disabled) {
                        return undefined;
                    }
                    checkbox.checked = !checkbox.checked;
                    const index = parseInt(checkbox.getAttribute('data-index'), 10);
                    const column = this.columns[index];
                    const hidden = !checkbox.checked;

                    if (Boolean(column.hidden) !== hidden) {
                        this.ngZone.run(() => {
                            column.hidden = hidden;
                            this.columnChange.emit([column]);
                        });
                    }
                }
            });
        });
    }

    ngOnDestroy(): void {
        if (this.domSubscriptions) {
            this.domSubscriptions();
        }
    }

    cancelChanges(): void {
        const changed = [];
        this.columns.forEach(column => {
            const oCol = this.originalColumns.find(o => o.field === column.field);
            if (Boolean(column.hidden) !== Boolean(oCol.hidden)) {
                column.hidden = oCol.hidden;
                changed.push(column);
            }
        });

        this.updateDisabled();

        this.reset.emit(changed);
    }

    trackByColumnField = (index: number, col: any): string => {
        return col.field;
    };

    private forEachCheckBox(callback: any): void {
        const checkboxes = this.element.nativeElement.getElementsByTagName('input');
        const length = checkboxes.length;
        for (let idx = 0; idx < length; idx++) {
            callback(checkboxes[idx], idx);
        }
    }

    private updateDisabled(): void {
        if (!this.hasLocked) {
            return;
        }

        const checkedItems = [];
        this.forEachCheckBox((checkbox, index) => {
            if (checkbox.checked) {
                checkedItems.push({ checkbox, index });
            }
            checkbox.disabled = false;
        });

        if (checkedItems.length === 1 && !this.hasFiltered) {
            checkedItems[0].checkbox.disabled = true;
        } else if (this.hasLocked && !this.hasUnlockedFiltered) {
            const columns = this.columns;
            const checkedUnlocked = checkedItems.filter(item => !columns[item.index].locked);

            if (checkedUnlocked.length === 1) {
                checkedUnlocked[0].checkbox.disabled = true;
            }
        }
    }

    private updateColumnState(): void {
        this.hasLocked = this.allColumns.filter(column => column.locked && (!column.hidden || column.includeInChooser !== false)).length > 0;
        this.hasVisibleLocked = this.allColumns.filter(column => column.locked && !column.hidden).length > 0;
        this.unlockedCount = this.columns.filter(column => !column.locked && !column.hidden).length;

        const filteredColumns = this.allColumns.filter(column => column.includeInChooser === false && !column.hidden);
        if (filteredColumns.length) {
            this.hasFiltered = filteredColumns.length > 0;
            this.hasUnlockedFiltered = filteredColumns.filter(column => !column.locked).length > 0;
        } else {
            this.hasFiltered = false;
            this.hasUnlockedFiltered = false;
        }
    }

    hasClasses = (element: HTMLElement, classNames: string): boolean => {
        const namesList = this.toClassList(classNames);

        return Boolean(this.toClassList(element.className).find((className) => namesList.indexOf(className) >= 0));
    };

    toClassList = (classNames: string) => String(classNames).trim().split(' ');
}
