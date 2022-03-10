import { Directive, ElementRef, Input, OnInit, Renderer2 } from '@angular/core';

@Directive({
    selector: '[kendogrid-drag-item]'
})

export class IpxKendoGridDragItemDirective implements OnInit {
    @Input('kendogrid-drag-item') kendoItem: any;

    constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) { }

    ngOnInit(): void {
        const dataItem = this.kendoItem;
        const tableRow = this.el.nativeElement.parentElement.parentElement;
        this.renderer.setStyle(tableRow, 'cursor', 'all-scroll');
        this.renderer.setAttribute(tableRow, 'draggable', 'true');
        this.renderer.setAttribute(tableRow, 'data-item', JSON.stringify(dataItem));
    }
}