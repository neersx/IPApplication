import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'validator-examples',
  templateUrl: './validator-examples.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ValidatorExamplesComponent {
  minLengthValue: string;
  maxLengthValue: string;
  regexValue: string;
}
