import { Directive, ElementRef, Input, OnInit, Renderer2 } from '@angular/core';

@Directive({
    selector: '[kendotree-drag-item]'
})

export class KendoTreeDragItemDirective implements OnInit {
    @Input('kendotree-drag-item') kendoItem: any;

    constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) { }

    ngOnInit(): void {
        const dataItem = this.kendoItem;
        const spanEl = this.el.nativeElement.parentElement;
        this.renderer.addClass(spanEl, 'editbtnhide');
        this.renderer.setAttribute(spanEl, 'data-item', JSON.stringify(dataItem));
        this.renderer.setAttribute(spanEl, 'draggable', 'true');
        if (dataItem.saved) {
            this.renderer.addClass(this.el.nativeElement, 'treeview-saved');
        }
    }
}