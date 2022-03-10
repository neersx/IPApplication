// tslint:disable: no-use-before-declare
import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'ipx-picklist-search-field',
  templateUrl: './ipx-picklist-search-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxPicklistSearchFieldComponent {
  navigation: NavigationEnum = NavigationEnum.current;
  @Input() model: string;
  @Input() disabled = false;
  @Input() placeholder: string;
  @Output() readonly onSearch = new EventEmitter<any>();
  @Output() readonly onClear = new EventEmitter<any>();
  @Output() readonly onKeyUp = new EventEmitter<any>();
  @Output() readonly onEnter = new EventEmitter<any>();

  search(): void {
    const eventValue = { value: this.model, action: this.navigation };
    this.onSearch.emit(eventValue);
  }

  keyUp(): void {
    const eventValue = { value: this.model, action: this.navigation };
    this.onKeyUp.emit(eventValue);
  }

  enter(): void {
    const eventValue = { value: this.model, action: this.navigation };
    this.onEnter.emit(eventValue);
  }

  clear(): void {
    this.model = '';
    this.navigation = NavigationEnum.current;
    this.onClear.emit();
  }
}

export enum NavigationEnum {
  first = 'firstPage',
  previous = 'previousPage',
  current = '',
  focus = 'setFocus',
  next = 'nextPage',
  last = 'lastPage',
  filtersChanged = 'filtersChanged'
}
