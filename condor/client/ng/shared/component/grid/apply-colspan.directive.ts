import { Directive, ElementRef, Input, OnInit, Renderer2 } from '@angular/core';

@Directive({
    selector: '[apply-colspan]'
})

export class ApplyColSpanDirective implements OnInit {
    @Input('apply-colspan') columnsCount: any;

    constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) { }

    ngOnInit(): void {
        const columnsCount = this.columnsCount;
        const tableCell = this.el.nativeElement.parentElement;
        this.renderer.setAttribute(tableCell, 'colspan', columnsCount);
    }
}