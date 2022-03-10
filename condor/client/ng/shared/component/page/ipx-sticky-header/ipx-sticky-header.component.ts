import { AfterContentInit, AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, OnDestroy, OnInit, Renderer2 } from '@angular/core';
import * as ResizeSensor from 'css-element-queries/src/ResizeSensor';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-sticky-header',
    template: '<div><ng-content></ng-content></div>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxStickyHeaderComponent implements OnInit, OnDestroy, AfterViewInit, AfterContentInit {

    sensor: ResizeSensor;
    rendererListener: any;

    constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) {
    }

    ngOnInit(): any {
        if (!this.el.nativeElement.length) {
            return;
        }
    }

    ngAfterViewInit(): void {
        const debounceAdjust = _.debounce(this.adjustMargin, 100);
        debounceAdjust();
        this.rendererListener = this.renderer.listen(window, 'resize', debounceAdjust);
    }

    ngAfterContentInit(): void {
        this.sensor = new ResizeSensor(this.el.nativeElement.children[0], this.adjustMargin);
    }

    ngOnDestroy(): void {
        if (this.sensor) {
            this.sensor.detach();
        }
        this.rendererListener();
    }

    adjustMargin = (): any => {
        const height = this.el.nativeElement.clientHeight;
        this.renderer.setStyle(this.el.nativeElement.parentElement, 'padding-top', (height + 'px').toString());
    };
}
