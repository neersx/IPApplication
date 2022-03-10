import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';

@Component({
  selector: 'dropdown-operator',
  templateUrl: './dropdown-operator-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DropdownOperatorExampleComponent implements OnInit {
  selectedValuedrop: any;
  selectedValuedisable: any;
  isDisabled: boolean;

  ngOnInit(): void {
    this.selectedValuedrop = '1';
    this.selectedValuedisable = '2';
  }
}
