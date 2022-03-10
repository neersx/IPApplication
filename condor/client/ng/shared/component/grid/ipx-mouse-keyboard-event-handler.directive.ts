import { Directive, ElementRef, EventEmitter, Input, OnDestroy, OnInit, Output, Renderer2 } from '@angular/core';
import { EnterPressedEvent, RowState } from './ipx-grid.models';
import { IpxKendoGridComponent } from './ipx-kendo-grid.component';

@Directive({
    selector: '[ipxKeyboardEventHandler]'
})
export class MouseKeyboardEventHandlerDirective implements OnInit, OnDestroy {
    @Input() wrap = true;
    @Output() readonly onEnter = new EventEmitter<EnterPressedEvent>();

    private unsubKeydown: () => void;

    constructor(private readonly grid: IpxKendoGridComponent,
        private readonly el: ElementRef,
        private readonly renderer: Renderer2) {
    }

    ngOnInit(): void {
        this.unsubKeydown = this.renderer.listen(
            this.el.nativeElement, 'keydown', (e) => this.onKeydown(e)
        );
    }

    ngOnDestroy(): void {
        this.unsubKeydown();
    }

    onKeydown(e: KeyboardEvent): void {
        const activeRow = this.grid.wrapper.activeRow;
        if (!activeRow || !activeRow.dataItem) {
            return;
        }

        switch (e.key) {
            case 'Tab': this._handleTabForDateInput(e);
                break;
            case 'Enter': this._handleEnter();
                break;
            default: break;
        }
    }

    private _handleTabForDateInput(e: KeyboardEvent): void {
        if (!this.el.nativeElement.querySelector('.k-grid-edit-row .k-state-focused kendo-dateinput')) {
            return;
        }

        const nav = e.shiftKey ?
            this.grid.wrapper.focusPrevCell(this.wrap) :
            this.grid.wrapper.focusNextCell(this.wrap);

        if (!nav) {
            return;
        }

        const inputEle = nav.colIndex > 0
            ? this.el.nativeElement.querySelector(`.k-grid-edit-row > td:nth-child(${nav.colIndex + 1}) input`)
            : this.el.nativeElement.querySelector('.k-grid-edit-row + tr.k-detail-row input');

        if (!!inputEle) {
            inputEle.focus();
        }

        e.preventDefault();
    }

    private _handleEnter(): void {
        if (!this.grid.wrapper.activeCell) {
            return;
        }

        const rowState = this._fetchRowState(this.grid.wrapper.activeCell.dataRowIndex);
        this.onEnter.next(new EnterPressedEvent(this.grid.wrapper.activeCell.dataItem, rowState, this.grid.wrapper.activeCell.colIndex));
    }

    private _fetchRowState(rowIndex: number): RowState {
        const currentRow = this.el.nativeElement.querySelectorAll('tbody tr:not(.k-detail-row)')[rowIndex];

        if (!!currentRow) {
            const isExpanded = currentRow.classList.contains('open');
            const isInEdit = currentRow.classList.contains('k-grid-edit-row');

            return new RowState(isExpanded, isInEdit);
        }

        return null;
    }
}