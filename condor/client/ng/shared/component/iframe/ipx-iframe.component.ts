import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit, Renderer2, ViewChild } from '@angular/core';

@Component({
  selector: 'ipx-iframe',
  templateUrl: 'ipx-iframe.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxIframeComponent implements OnInit {

  @Input('src') srcUrl: string;
  @Input() isSandbox: string;
  @Input('topic-key') topicKey: string;
  @ViewChild('iframe') iframe: ElementRef;
  height: string;
  private el: any;
  isLoaded: boolean;
  hasError = false;
  isExpanded = false;
  constructor(private readonly renderer: Renderer2) {
  }

  ngOnInit(): void {
    setTimeout(() => {
      this.el = this.iframe.nativeElement;

      if (this.isSandbox) {
        this.renderer.setAttribute(this.el, 'sandbox', 'allow-forms allow-scripts allow-popups');
      }
    }, 500);

  }

  onLoad(): void {
    if (this.srcUrl) {
      this.isLoaded = true;
      if (!this.isValidURL(this.srcUrl)) {
        this.hasError = true;
      }
      setTimeout(() => {
        if (this.isLoaded) {
          return;
        }

        this.isLoaded = true;
      }, 10000);
    }
  }

  propagateHeightChange(event): void {
    this.height = event;
    this.isExpanded = event === '100vh' ? true : false;
    const topicEl: HTMLElement = this.el.offsetParent.querySelector('.topic-container[data-topic-key="' + this.topicKey + '"]');

    const rootElm = this.el.offsetParent.querySelector('ipx-topics');
    const adjustLength = rootElm.querySelector('ipx-topics div[name="topics"]');
    const scrollTop = topicEl.offsetTop - (adjustLength.offsetTop + 5);
    const el = this.el.offsetParent.querySelector('ipx-topics div[name="topics"].main-content-scrollable');

    el.scrollTop = scrollTop;
  }

  isValidURL = (urlString: string): boolean => {
    const elm = document.createElement('input');
    elm.setAttribute('type', 'url');
    elm.value = urlString;

    return elm.validity.valid;
  };
}
