import { Directive, ElementRef, EventEmitter, Input, OnDestroy, Output } from '@angular/core';
import { BehaviorSubject, interval } from 'rxjs';
import { distinctUntilChanged, filter, skip, throttle } from 'rxjs/operators';

@Directive({
  selector: '[ipx-dom-change-handler]'
})
export class IpxDomChangeHandlerDirective implements OnDestroy {

  private readonly domChanges: MutationObserver;
  private readonly $height = new BehaviorSubject(0);
  @Output() private readonly heightChange = new EventEmitter<string>();

  constructor(private readonly el: ElementRef) {
    const element = this.el.nativeElement;
    this.domChanges = new MutationObserver(() => {
      this.$height.next(this.getFullContentHeight(element));
    });

    this.el.nativeElement.style.cssText = 'overflow: visible';

    this.$height
      .pipe(
        throttle(() => interval(50)),
        distinctUntilChanged(),
        filter(h => h > 0))
      .subscribe((h) => {
        this.heightChange.emit(h.toString());
      });

    this.domChanges.observe(element, {
      childList: true,
      attributes: false,
      subtree: true
    });
  }

  ngOnDestroy(): void {
    this.domChanges.disconnect();
  }

  triggerResize = () => {
    this.$height.next(this.getFullContentHeight(this.el.nativeElement));
  };

  getFullContentHeight = (element: any) => {
    const resizableContent = element.querySelectorAll('.main-content-scrollable'); // If resize handler is presented
    if (resizableContent.length === 1) {
      const resizablePanel = resizableContent[0].querySelectorAll('.table-container');
      if (resizablePanel.length === 1) {
        return resizablePanel[0].scrollHeight + 340;
      }

      return resizableContent[0].scrollHeight + 290;
    }
    const borderHeight = element.offsetHeight - element.clientHeight;

    return element.scrollHeight + borderHeight;
  };
}
