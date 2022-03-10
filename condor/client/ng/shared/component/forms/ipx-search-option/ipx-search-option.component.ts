import { ChangeDetectionStrategy, Component, ContentChild, EventEmitter, Input, Output } from '@angular/core';
import { FocusService } from 'shared/component/focus';
import { InputRefDirective } from '../ipx-inputref.directive ';

@Component({
  selector: 'ipx-search-option',
  templateUrl: './ipx-search-option.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SearchOptionComponent {
  @Input() isSearchDisabled: false;
  @Input() isResetDisabled: false;
  @Input() showButtonText: false;
  @Input() hideControls = false;
  @Output() readonly clear = new EventEmitter();
  @Output() readonly search = new EventEmitter();
  @ContentChild(InputRefDirective, { static: false }) inputRef: InputRefDirective;
  isCollapsed = false;
  constructor(private readonly focusService: FocusService) {
  }

  onClear = () => {
    if (!this.isResetDisabled) {
      this.clear.emit();
    }
  };

  doSearch = () => {
    if (!this.isSearchDisabled) {
      this.search.emit();
    }
  };

  onValidate = () => {
    this.doSearch();
  };

  setFocus = () => {
    if (!this.inputRef) { return; }
    this.focusService.autoFocus(this.inputRef.elementRef);
  };
}
