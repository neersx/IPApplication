import { Directive, ElementRef, Input, OnDestroy, OnInit, Renderer2 } from '@angular/core';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { BusService } from 'core/bus.service';
import * as ResizeSensor from 'css-element-queries/src/ResizeSensor';
import * as _ from 'underscore';

@Directive({
  selector: '[ipx-resize-handler]',
  exportAs: 'resizeHandlerDirective'
})
export class IpxResizeHandlerDirective implements OnInit, OnDestroy {

  @Input('resize-handler-type') resizeHandlerType: string;
  @Input('resize-header-height') resizeHeaderHeight = 0;

  element: HTMLElement;
  isScrollablePaneMode: boolean;
  adjustHeight: any;
  containerSensor: any;
  rendererListener: any;

  private isHosted = false;

  constructor(private readonly el: ElementRef, private readonly renderer: Renderer2, private readonly bus: BusService, private readonly rootscopeService: RootScopeService) {
    this.element = (this.el.nativeElement);
  }

  ngOnInit(): void {
    // tslint:disable-next-line:no-string-literal
    this.isHosted = this.rootscopeService.rootScope['isHosted'];
    this.isScrollablePaneMode = this.resizeHandlerType ? this.resizeHandlerType.toUpperCase() === 'PANEL' : false;
    if (this.isScrollablePaneMode) {
      this.renderer.addClass(this.element, 'main-content-scrollable');
    }
    this.adjustHeight = this.initAdjustHeight(this.element);
    setTimeout(this.adjustHeight, 10);

    this.rendererListener = this.renderer.listen(window, 'resize', this.adjustHeight);
    this.containerSensor = this.tryInitContainerSensor();
    this.bus.channel('resize').subscribe(this.adjustHeight);
  }

  initAdjustHeight = (element: any) => {
    return _.debounce(() => {
      if (!this.containerSensor) {
        this.containerSensor = this.tryInitContainerSensor();
      }
      const availableHeight = this.getAvailableHeight(element);
      const fullContentHeight = this.getFullContentHeight(element);

      const heightToFit = (this.isScrollablePaneMode) ? (availableHeight - 40) : Math.min(fullContentHeight, availableHeight);
      if (!this.isHosted) {
        this.renderer.setStyle(element, 'height', heightToFit + this.resizeHeaderHeight + 'px');
      }
    }, 50);
  };

  getAvailableHeight = (element: any) => {
    const pageHeight = (document.querySelector('html') as any).clientHeight;
    const elementPositionTop = element.offsetTop;
    const containerPositionTop = element.offsetParent != null ? element.offsetParent.offsetTop : 0;

    return pageHeight - containerPositionTop - elementPositionTop - 5;
  };

  getFullContentHeight = (element: any) => {
    const borderHeight = element.offsetHeight - element.clientHeight;

    return element.scrollHeight + borderHeight;
  };

  tryInitContainerSensor = () => {
    const parentOffset = this.element.offsetParent;
    if (!parentOffset || parentOffset === document.querySelector('html')[0]) {
      return null;
    }

    return new ResizeSensor(parentOffset, this.adjustHeight);
  };

  ngOnDestroy(): void {
    if (this.containerSensor) {
      this.containerSensor.detach();
    }

    this.rendererListener();
    this.bus.channel('resize').unsubscribe(this.adjustHeight);
  }
}
