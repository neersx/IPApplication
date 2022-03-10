import { Directive, ElementRef, EventEmitter, Injector, Input, Output } from '@angular/core';
import { UpgradeComponent } from '@angular/upgrade/static';

@Directive({
  selector: 'ip-datepicker-ng'
})

export class DatePickerDirective extends UpgradeComponent {
  @Input() class: string;
  @Input() label: string;
  @Input() isDisabled: any;
  @Input() readonly: any;
  @Output() readonly onblur: EventEmitter<any> = new EventEmitter<any>();
  @Input() ngModel: any;
  @Input() earlierThan: any;
  @Input() laterThan: any;
  @Input() includeSameDate: any;
  @Input() isSaved: any;
  @Input() isDirty: any;
  @Input() inlineDataItemId: string;
  @Input() noEditState: any;
  @Input() isRequired: any;
  @Input() useLocalTimezone: boolean;

  constructor(elementRef: ElementRef, injector: Injector) {
    super('ipDatePickerWrapper', elementRef, injector);
  }
}
