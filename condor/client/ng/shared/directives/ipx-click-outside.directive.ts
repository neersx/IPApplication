import { Directive, ElementRef, EventEmitter, HostListener, Output } from '@angular/core';

@Directive({
  selector: '[clickOutside]'
})
export class IpxClickOutsideDirective {
  constructor(private readonly _elementRef: ElementRef) {
  }

  @Output() readonly clickOutside = new EventEmitter();

  @HostListener('document:click', ['$event.target']) onClick = (targetElement): void => {
    const clickedInside = this._elementRef.nativeElement.contains(targetElement);
    if (!clickedInside) {
      this.clickOutside.emit(null);
    }
  };
}
