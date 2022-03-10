import { Directive, ElementRef, OnInit } from '@angular/core';

@Directive({
  selector: '[elementwidth]'
})
export class ElementComputedStyleDirective implements OnInit {

  constructor(private readonly el: ElementRef) {
  }

  ngOnInit(): any {
    const element = this.el.nativeElement;

    element.width = (): any => {
      const computedStyle = getComputedStyle(element);
      let width = element.clientWidth; // width with padding
      width -= parseFloat(computedStyle.paddingLeft) + parseFloat(computedStyle.paddingRight);

      return width;
    };
  }

}
