import { Directive, forwardRef, Input } from '@angular/core';
import { NG_VALIDATORS } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { IpxRegexDirective } from './ipx-regex.directive';

@Directive({
  selector: '[ipx-email]',
  providers: [
      { provide: NG_VALIDATORS, useExisting: forwardRef(() => IpxEmailDirective), multi: true }
  ]
})
export class IpxEmailDirective extends IpxRegexDirective {
  regex =  /^[_a-zA-Z0-9]+(\.[_a-zA-Z0-9]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/;
  regexMessage = 'field.errors.ipEmail';
  constructor(translate: TranslateService) {
    super(translate);
  }
}