import { ChangeDetectionStrategy, Component, ElementRef, EventEmitter, Input, OnDestroy, OnInit, Output, Renderer2, ɵ_sanitizeHtml } from '@angular/core';
import * as _ from 'underscore';
import { TemplateType } from './autocomplete/template.type';

@Component({
  selector: 'ipx-autocomplete',
  templateUrl: './ipx-autocomplete.html',
  styleUrls: ['./ipx-autocomplete.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxAutocompleteComponent implements OnDestroy, OnInit {
  @Input() options: any;
  @Input() text: string;
  @Input() results: any;
  @Input() recentResult: any;
  @Input() total: number;
  @Output() readonly selectedRowEvent = new EventEmitter<string>();
  @Output() readonly listClickedEvent = new EventEmitter<boolean>();

  templateType: TemplateType;
  keyField: string;
  codeField: string;
  textField: string;
  autoCompleteElement: any;
  highlighted: any;
  suggestionList: any;
  completeResultSet: any;

  constructor(private readonly el: ElementRef, private readonly renderer: Renderer2) {
  }

  setSelectedRow(item): void {
    this.selectedRowEvent.emit(item);
  }

  onClick(isClicked): void {
    this.listClickedEvent.emit(isClicked);
  }

  ngOnInit(): any {
    this.templateType = this.options.templateType;
    this.keyField = this.options.keyField;
    this.codeField = this.options.codeField;
    this.textField = this.options.textField;
  }

  ngOnDestroy(): any {
    this.autoCompleteElement = this.el.nativeElement.querySelector('.autocomplete');
    if (this.autoCompleteElement) {
      this.autoCompleteElement.remove = this.removeAutoComplete;
    }
  }

  removeAutoComplete(this: any): any {
    if (this.parentNode) {
      this.parentNode.removeChild(this);
    }
  }

  select(): any {
    if (!this.hasItems()) {
      return false;
    }

    const highlighted = this.el.nativeElement.parentElement.querySelector('.autocomplete .suggestion-item.highlighted');

    if (highlighted) {
      const id = highlighted.id;
      const item = this.completeResultSet[id];
      this.selectedRowEvent.emit(item);
    }

    return false;
  }

  movePrevious(): any {
    if (!this.hasItems()) {
      return;
    }

    this.highlighted = this.el.nativeElement.querySelector('.suggestion-item.highlighted');
    this.suggestionList = this.el.nativeElement.querySelector('.suggestion-list');

    if (!this.highlighted) {
      this.renderer.addClass(this.suggestionList.lastElementChild, 'highlighted');
    } else {
      this.manageHighlightedClass(this.highlighted.previousElementSibling, 'prev');
    }
  }

  moveNext(): any {
    if (!this.hasItems()) {
      return;
    }

    this.highlighted = this.el.nativeElement.querySelector('.suggestion-item.highlighted');
    this.suggestionList = this.el.nativeElement.querySelector('.suggestion-list');

    if (!this.highlighted) {
      this.renderer.addClass(this.suggestionList.firstElementChild, 'highlighted');
    } else {
      this.manageHighlightedClass(this.highlighted.nextElementSibling, 'next');
    }
  }

  manageHighlightedClass(element: any, type: string): any {
    this.renderer.removeClass(this.highlighted, 'highlighted');

    if (element) {
      this.renderer.addClass(element, 'highlighted');
      this.scrollToView(element);
    }

    if (!element && type === 'prev') {
      this.renderer.addClass(this.suggestionList.lastElementChild, 'highlighted');
      this.scrollToView(this.suggestionList.lastElementChild);
    } else if (!element && type === 'next') {
      this.renderer.addClass(this.suggestionList.firstElementChild, 'highlighted');
      this.scrollToView(this.suggestionList.firstElementChild);
    }
  }

  resetClass(): void {
    const highlights = this.el.nativeElement.getElementsByClassName('highlighted');
    for (const value of highlights) {
      this.renderer.removeClass(value, 'highlighted');
    }
  }

  scrollToView(elm): void {
    if (!elm) {
      return;
    }
    const element = this.el.nativeElement;
    const height = elm.clientHeight;
    const suggestionListElement = element.querySelector('.suggestion-list');
    const offsetTop = elm.offsetTop - suggestionListElement.scrollTop;
    const scrollTop = suggestionListElement.scrollTop;
    const containerHeight = suggestionListElement.clientHeight;
    const top = offsetTop;
    const bottom = top + height;

    if (bottom > containerHeight) {
      suggestionListElement.scrollTop = scrollTop + bottom - containerHeight;
    }
    if (top < 0) {
      suggestionListElement.scrollTop = top;
    }
  }

  hasItems(): boolean {
    return !!this.completeResultSet && this.completeResultSet.length > 0;
  }

  getResultSet(): any {
    let recentResult = [];
    let results = [];

    if (!!this.recentResult) {
      recentResult = [...this.recentResult];
      _.last(recentResult).lastRecentResult = true;
    }
    if (!!this.results) {
      results = [...this.results];
    }

    this.completeResultSet = _.uniq(recentResult.concat(results), false, _.property(this.keyField));

    return this.completeResultSet;
  }

  displayCount(): boolean {
    return this.recentResult == null && this.results != null && this.total > this.results.length && this.total > 1;
  }
}
