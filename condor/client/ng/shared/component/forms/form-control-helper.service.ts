import { ElementRef, Injectable } from '@angular/core';

@Injectable()
export class FormControlHelperService {

  element: any;
  className: any;
  formCtrl: any;

  constructor(private readonly el: ElementRef) {
  }

  init(args): any {
    const nativeEl = this.el.nativeElement;
    nativeEl.classList.add('ip-typeahead');
    this.className = nativeEl.classList;
    this.element = nativeEl;
    this.formCtrl = args.form;
  }
}
