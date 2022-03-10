import { AbstractControl, ValidationErrors, Validator } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';

export abstract class IpxRegexDirective implements Validator {
  regex: RegExp | string;
  regexMessage = 'field.errors.regexDefault';
  constructor(private readonly translate: TranslateService) { }
  validate(control: AbstractControl): ValidationErrors {
    if (this.regex && control.value) {
      const regex = typeof this.regex === 'string' ? new RegExp(this.regex) : ((this.regex as any) as RegExp);
      if (!regex.test(control.value)) {
        return {
          regex: {
            regex: this.regex,
            regexMessage: this.translate.instant(this.regexMessage || 'field.errors.regexDefault')
          }
        };
      }
    }

    return null;
  }
}