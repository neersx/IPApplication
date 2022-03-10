import { ChangeDetectionStrategy, Component, Input, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { ElementBaseComponent } from '../element-base.component';

@Component({
  selector: 'ipx-checkbox',
  templateUrl: './ipx-checkbox.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxCheckboxComponent extends ElementBaseComponent<boolean> implements OnInit, OnChanges {

  @Input() label: string;
  @Input() labelValues: any;
  @Input() info: any;
  @Input() infoData: any;
  @Input() infoPlacement: string;
  showError$ = new BehaviorSubject(false);

  ngOnInit(): void {
    // tslint:disable-next-line: strict-boolean-expressions
    this.label = this.label || '';
    const attr = this.el.nativeElement.attributes;
    if (attr.disabled) {
      this.disabled = true;
    }
  }

  onClick(): any {
    if (!this.disabled) {
      this.value = !this.value;
      this._onChange(this.value);
      this.onChange.emit(this.value);
    }
  }

  valueChanged(): any {
    if (!this.disabled) {
      this._onChange(this.value);
      this.onChange.emit(this.value);
    }
  }

  writeValue = (value: any) => {
    this.value = value;
  };

  ngOnChanges(changes: SimpleChanges): void {
    this.showError$.next(this.showError());
  }
}
