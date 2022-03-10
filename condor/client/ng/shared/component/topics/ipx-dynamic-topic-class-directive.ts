import { Directive, ElementRef, Input, OnInit, Renderer2 } from '@angular/core';

@Directive({
    selector: '[dynamic-topic-class]'
})

export class IpxDynamicTopicClassDirective implements OnInit {
    @Input('dynamic-topic-class') className: any;

    constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) { }

    ngOnInit(): void {
        if (this.className) {
            this.renderer.addClass(this.el.nativeElement, this.className);
        }
    }
}
