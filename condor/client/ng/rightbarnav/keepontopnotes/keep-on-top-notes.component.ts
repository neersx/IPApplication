import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnInit, Renderer2 } from '@angular/core';
import { KotModel } from './keep-on-top-notes-models';

@Component({
    selector: 'ipx-kot-panel',
    templateUrl: './keep-on-top-notes.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class KeepOnTopNotesComponent implements AfterViewInit, OnInit {
    itemsPerSlide = 3;
    singleSlideOffset = false;
    noWrap = false;
    showIndicators = true;

    @Input() notes: Array<KotModel>;
    constructor(readonly cdref: ChangeDetectorRef, private readonly el: ElementRef, private readonly renderer: Renderer2) { }

    ngOnInit(): void {
        if (this.checkNotesLength()) {
            this.itemsPerSlide = this.notes.length;
            this.showIndicators = false;
        }
    }

    ngAfterViewInit(): void {
        if (this.checkNotesLength()) {
            this.removeNavigationButtons();
        }
    }

    checkNotesLength(): boolean {
        return this.notes && this.notes.length <= 3;
    }

    removeNavigationButtons = (): void => {
        const rightNavigationEle = this.el.nativeElement.querySelector('.right');
        const leftNavigationEle = this.el.nativeElement.querySelector('.left');

        if (rightNavigationEle) {
            this.renderer.removeChild(this.el.nativeElement, rightNavigationEle);
        }
        if (leftNavigationEle) {
            this.renderer.removeChild(this.el.nativeElement, leftNavigationEle);
        }
    };

    hasNotes = (): boolean => {
        return this.notes && this.notes.length > 0;
    };

    trackByFn = (index: number, item: any): number => {
        return index;
    };

    clickKotNote = (kot: KotModel): void => {
        kot.expanded = !kot.expanded;
    };
}
