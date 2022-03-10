import { Directive, ElementRef, Input, OnInit, Renderer2 } from '@angular/core';

@Directive({
    selector: '[kendotree-drag-item-example]'
})

export class KendoTreeDragItemExampleDirective implements OnInit {
    @Input('kendotree-drag-item-example') kendoItem: any;

    constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) { }

    ngOnInit(): void {
        const dataItem = this.kendoItem;
        const tableRow = this.el.nativeElement.parentElement.parentElement;
        this.renderer.setStyle(tableRow, 'cursor', 'all-scroll');
        this.renderer.setAttribute(tableRow, 'draggable', 'true');
        this.renderer.setAttribute(tableRow, 'data-item', JSON.stringify(dataItem));
    }
}