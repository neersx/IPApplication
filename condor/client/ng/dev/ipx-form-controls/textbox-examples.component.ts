import { ChangeDetectionStrategy, Component, ElementRef, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { FocusService } from 'shared/component/focus';
@Component({
  selector: 'textbox-examples',
  templateUrl: './textbox-examples.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxTextBoxExampleComponent {
  code: string;
  mirror: string;
  warning: string;
  passwordText: string;
  multiLineText: string;
  multiLineTextRequired: string;
  codeChanged: string;
  devname: string;
  @ViewChild('nextForm', { static: true }) readonly nextForm: NgForm;
  private divElementRef: ElementRef;
  @ViewChild('devInput', { static: true }) set controlElRef(elementRef: ElementRef) {
    this.divElementRef = elementRef;
  }

  constructor(private readonly focusService: FocusService) {
    this.code = 'US';
    this.passwordText = 'internal';
    this.devname = 'i m disabled';
  }

  onCodeChange = (event: Event) => {
    this.codeChanged = this.code;
  };

  selectFocus = () => {
    setTimeout(() => {
      this.focusService.autoFocus(this.divElementRef);
    });
  };
}
