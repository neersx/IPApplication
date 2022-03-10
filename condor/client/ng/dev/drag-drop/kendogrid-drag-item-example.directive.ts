import { Directive, ElementRef, Input, OnInit, Renderer2 } from '@angular/core';

@Directive({
 selector: '[kendogrid-drag-item-example]'
})

export class KendoGridDragItemExampleDirective implements OnInit {
    @Input('kendogrid-drag-item-example') kendoItem: any;

    constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) {}

    ngOnInit(): void {
        const dataItem = this.kendoItem;

        const spanEl = this.el.nativeElement.parentElement;
        this.renderer.setAttribute(spanEl, 'data-item', JSON.stringify(dataItem));
        this.renderer.setAttribute(spanEl, 'draggable', 'true');
    }
}