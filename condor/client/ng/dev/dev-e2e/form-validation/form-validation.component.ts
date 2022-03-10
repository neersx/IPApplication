import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'form-validation',
  templateUrl: './form-validation.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FormValidationComponent {
  minLengthValue: string;
  maxLengthValue: string;
  emailValue: string;
}
