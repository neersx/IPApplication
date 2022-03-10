// tslint:disable:max-file-line-count
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, HostBinding, HostListener, Input, OnChanges, OnDestroy, OnInit, Optional, Renderer2, Self, SimpleChanges, TemplateRef, ViewChild } from '@angular/core';
import { NgControl } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject, Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';
import { ElementBaseComponent } from 'shared/component/forms/element-base.component';
import { FormControlHelperService } from 'shared/component/forms/form-control-helper.service';
import * as _ from 'underscore';
import { TemplateType } from '../ipx-autocomplete/autocomplete/template.type';
import { IpxAutocompleteComponent } from '../ipx-autocomplete/ipx-autocomplete';
import { IpxModalOptions } from '../ipx-picklist/ipx-picklist-modal-options';
import { IpxPicklistModalService } from '../ipx-picklist/ipx-picklist-modal.service';
import { IpxTypeaheadService } from './ipx-typeahead.service';
import { PositionToShowCodeEnum } from './position-to-show-code-enum';
import { TagsErrorValidator, TypeaheadConfig, TypeAheadConfigProvider } from './typeahead.config.provider';

@Component({
  selector: 'ipx-typeahead',
  templateUrl: './ipx-typeahead.html',
  providers: [FormControlHelperService],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxTypeaheadComponent extends ElementBaseComponent implements OnInit, AfterViewInit, OnDestroy, OnChanges {
  @Input() config: string;
  @Input() placeholder: string;
  @Input('entity') entity: string;
  @Input('key-field') keyField: string;
  @Input('code-field') codeField: string;
  @Input('text-field') textField: string;
  @Input('tag-field') tagField: string;
  @Input('api-url') apiUrl: string;
  @Input('picklist-columns') picklistColumns: any;
  @Input('max-results') maxResults: string;
  @Input('template-type') templateType: TemplateType;
  @Input('label') label: string;
  @Input('picklistCanMaintain') picklistCanMaintain: boolean;
  @Input('extend-query') extendQuery: any;
  @Input('extended-params') extendedParams: any;
  @Input('external-scope') externalScope?: any;
  @Input('include-recent') includeRecent = false;
  @Input('picklist-display-name') picklistDisplayName: string;
  @Input('tooltipConfig') tooltipConfig: { placement: string, templateRef: TemplateRef<any> };
  @Input('is-addanother') isAddAnother: boolean;
  @Input('show-tags-errors') showTagsError: boolean;
  @Input('can-navigate') canNavigate: boolean;
  @Input('picklistNewSearch') picklistNewSearch: boolean;
  @Input('not-found-error') notFoundError?: string;
  /**
   * auto-bind: when true this will auto-search when picklist is opened;
   * when false will default to typeahead config 'autobind' setting and only auto search when there is a search value.
   */
  @Input('auto-bind') autoBind?: boolean;
  @ViewChild('templateModal') templateModal;
  modalRef: BsModalRef;
  searchDebounce = 300;
  uid: any;
  isMultiSelect = false;
  isMultiPick = false;
  hasBlurred = false;
  results: any = null; // null: hide autocompelte, []: show no results
  recentResults: any = null;
  queryFieldUpdate = new Subject<string>();
  text: string;
  selectedItem: any;
  state: any = 'idle';
  loading: any;
  listClicked = false;
  options: TypeaheadConfig;
  attr: any;
  total: any;
  itemArray = [];
  callService: any;
  hasFocus: any;
  windowResizeListener: Function;
  identifier: string;
  displayText: string;
  positionToShowCodeEnum = PositionToShowCodeEnum;
  tagsErrorValidator: TagsErrorValidator;
  resultsFor: string;

  modalTitle = '';
  private subscription: Subscription;
  private modalHideSubscription: Subscription;
  private focusSubscription;
  private readonly picklistOptions: IpxModalOptions;
  private lastSearch: string = undefined;

  @ViewChild('autocompleteref') autoComplete: IpxAutocompleteComponent;

  constructor(
    private readonly typeaheadService: IpxTypeaheadService,
    public el: ElementRef,
    public renderer: Renderer2,
    private readonly picklistModalService: IpxPicklistModalService,
    private readonly typeaheadConfigProvider: TypeAheadConfigProvider,
    private readonly formcontrolhelper: FormControlHelperService,
    private readonly cdRef: ChangeDetectorRef,
    @Self() @Optional() public control: NgControl
  ) {
    super(control, el, cdRef);
    this.picklistOptions = new IpxModalOptions(false, '', [], false, false, '', '', null, null, false, false, false, '', false, false, false);
  }

  ngOnInit(): any {
    this.identifier = this.getId('typeahead');

    this.isMultiSelect = this.el.nativeElement.hasAttribute('multiselect');
    this.isMultiPick = this.el.nativeElement.hasAttribute('multipick');
    this.picklistOptions.multipick = this.isMultiPick;
    this.picklistOptions.picklistCanMaintain = this.el.nativeElement.hasAttribute('picklistCanMaintain');
    this.picklistOptions.picklistNewSearch = this.picklistNewSearch;
    this.picklistOptions.columnMenu = this.el.nativeElement.hasAttribute('columnMenu');

    this.results = null; // null: hide autocompelte, []: show no results

    this.queryFieldUpdate
      .pipe(debounceTime(this.searchDebounce))
      .subscribe(text => {
        if (this.callService) {
          this.callService.unsubscribe();
        }
        let updatedText = text;
        let code = '';
        const regexMatcher = /^[(].*[)]/;
        const trimmingRegex = /^\(+|\)+$/g;
        if (text.indexOf('(') === 0) {
          if (regexMatcher.test(text)) {
            const result = regexMatcher.exec(text);
            if (result) {
              code = result[0].replace(trimmingRegex, '');
            }
          } else {
            code = text.replace(trimmingRegex, '');
          }
        }
        if (this.options && this.options.showDisplayField && text.indexOf('(') === 0) { // if code + desc is displayed
          updatedText = code !== '' ? code : text.indexOf(')') > -1 && text.split(')')[1].trim().length > 0 ? text.split(')')[1].trim() : code;
        } else if (text.indexOf('(') === 0) {
          updatedText = code;
        }
        this.text = updatedText;
        this.textChange(updatedText);
        this.resultsFor = updatedText;
      });

    this.options = this.typeaheadConfigProvider.resolve(this.attrs());
    this.extendQuery = this.extendQuery || this.options.extendQuery;
    this.extendedParams = this.extendedParams || this.options.extendedParams;
    this.externalScope = this.externalScope || this.options.externalScope;
    this.placeholder = this.placeholder || this.options.placeholder;
    this.text = this.selectedItem ? this.getDisplayValue(this.selectedItem) : '';
    this.displayText = (this.options && this.options.showDisplayField && this.selectedItem) ? this.getDisplayText(this.selectedItem) : this.text;

    this.focusSubscription = this.onFocus.subscribe(() => {
      const elem = this.el.nativeElement.querySelector('input.typeahead');
      if (!!elem) {
        elem.focus();
      }
    });
  }

  ngAfterViewInit(): void {
    if (this.control) {
      this.formcontrolhelper.init(this.control.control);
    }
    if (this.isMultiSelect) {
      this.windowResizeListener = this.renderer.listen(window, 'resize', this.adjustMultiSelectInputWidth);
    }
    setTimeout(() => {
      this.cdRef.markForCheck();
    });
  }

  writeValue = (value: any): void => {
    this.isMultiSelect = this.el.nativeElement.hasAttribute && this.el.nativeElement.hasAttribute('multiselect') ? true : false;
    if (!this.isMultiSelect) {
      this.selectedItem = value;
      this.text = value ? this.getDisplayValue(this.selectedItem) : '';
      this.displayText = (this.options && this.options.showDisplayField && value) ? this.getDisplayText(this.selectedItem) : this.text;
    } else {
      this.itemArray = value ? (_.isArray(value) ? value : _.toArray(value))
        : [];
      this.adjustMultiSelectInputWidth();
    }

    this.cdRef.markForCheck(); // added this as clear button was not able to clear typeahead.
  };

  ngOnChanges(changes: SimpleChanges): void {
    if (changes.config) {
      this.options = this.typeaheadConfigProvider.resolve(this.attrs());
      this.extendQuery = this.extendQuery || this.options.extendQuery;
      this.extendedParams = this.extendedParams || this.options.extendedParams;
    }
  }

  ngOnDestroy(): any {
    if (this.isMultiSelect && this.windowResizeListener) {
      this.windowResizeListener();
    }

    if (this.subscription) {
      this.subscription.unsubscribe();
    }
    if (this.modalHideSubscription) {
      this.modalHideSubscription.unsubscribe();
    }
    if (this.focusSubscription) {
      this.focusSubscription.unsubscribe();
    }
  }

  openModal(): void {
    if (!this.disabled) {
      this.modalTitle = this.options.label;

      // tslint:disable-next-line: strict-boolean-expressions
      this.picklistOptions.searchValue = this.text || '';
      this.picklistOptions.selectedItems = [...this.itemArray];
      this.picklistOptions.extendQuery = this.extendQuery;
      this.picklistOptions.extendedParams = this.extendedParams;
      this.picklistOptions.externalScope = this.externalScope;
      this.picklistOptions.entity = this.entity && this.entity !== '' ? this.entity : undefined;
      this.picklistOptions.isAddAnother = this.isAddAnother;
      this.picklistOptions.canNavigate = this.canNavigate;

      this.modalRef = this.picklistModalService.openModal(this.picklistOptions, { ...this.options, ...(!!this.autoBind || !!this.options.autobind || this.picklistOptions.searchValue !== '' ? { autobind: true } : null) });
      if (this.modalRef) {
        this.subscription = this.modalRef.content.selectedRow$.subscribe(
          (event: any) => {
            const picklistDataObj: any = {};
            const mappedItem = event;
            picklistDataObj.dataItem = this.isMultiSelect ? mappedItem : mappedItem[0];
            picklistDataObj.options = this.options; // sending this, because in case there are multiple picklists ex: jurisd'n and naeRelationship, then its upto the consumer to handle it, based on the options sent.
            if (this.isMultiSelect) {
              this.itemArray = [];
              picklistDataObj.dataItem.forEach((data) => {
                this.selectItem(data, true);
              });
              this._onChange(this.itemArray);
              this.onChange.emit(this.itemArray);
            } else {
              this.selectItem(picklistDataObj.dataItem);
            }
          }
        );
        this.modalHideSubscription = this.modalRef.content.onClose$.subscribe(
          () => {
            this.cdRef.markForCheck();
            const inputElement = this.el.nativeElement.querySelector('input, textarea, select');
            if (inputElement) {
              inputElement.focus();
            } else {
              this.el.nativeElement.focus();
            }
          }
        );
      }
    }
  }
  getSelectedItems = () => this.itemArray;

  attrs = () => {
    const attrs: any = {};

    if (this.config) {
      attrs.config = this.config;
    }
    if (this.placeholder) {
      attrs.placeholder = this.placeholder;
    }
    if (this.keyField) {
      attrs.keyField = this.keyField;
    }
    if (this.codeField) {
      attrs.codeField = this.codeField;
    }
    if (this.textField) {
      attrs.textField = this.textField;
    }
    if (this.tagField) {
      attrs.tagField = this.tagField;
    }
    if (this.apiUrl) {
      attrs.apiUrl = this.apiUrl;
    }
    if (this.picklistColumns) {
      attrs.picklistColumns = this.picklistColumns;
    }
    if (this.picklistDisplayName) {
      attrs.picklistDisplayName = this.picklistDisplayName;
    }
    if (this.maxResults) {
      attrs.maxResults = this.maxResults;
    }
    if (this.templateType) {
      attrs.templateType = this.templateType;
    }
    if (this.label) {
      attrs.label = this.label;
    }

    return attrs;
  };

  keydown(argKeydown): void {
    switch (argKeydown.keyCode) {
      case 40:
        this.executeAction({
          type: 'key.down'
        });
        this.autoComplete.moveNext();
        argKeydown.stopPropagation();
        break;
      case 38:
        this.executeAction({
          type: 'key.down'
        });
        this.autoComplete.movePrevious();
        argKeydown.stopPropagation();
        break;
      case 13:
      case 9:
        if (this.autoComplete && this.autoComplete.hasItems()) {
          this.autoComplete.select();
        }
        argKeydown.stopPropagation();
        break;
      case 27:
        this.executeAction({
          type: 'key.esc'
        });
        argKeydown.stopPropagation();
        break;
      case 113:
        this.openModal();
        argKeydown.stopPropagation();
        break;
      case 35:
      case 36:
        argKeydown.stopPropagation();
        break;
      default:
    }
  }

  onSelected = index => {
    if (this.itemArray && this.itemArray.length > 0) {
      if (this.itemArray.length === 1) {
        this.itemArray[0].isTagSelected = true;
      } else {
        for (let i = 0; i < this.itemArray.length; i++) {
          this.itemArray[i].isTagSelected = index === i;
        }
      }
    }
  };

  onTagsKeydown(event): void {
    if (this.isMultiSelect) {
      switch (event.keyCode) {
        case 37: // left
          this.move(-1, false);
          break;
        case 39: // right
          this.move(1, false);
          break;
        case 8: // backspace
          if (!this.text) {
            this.move(-1, true);
          }
          break;
        case 46: // del
          if (!this.text) {
            this.move(1, true);
          }
          this.el.nativeElement.querySelector('input.typeahead').focus();
          break;
        default:
          this.clearSelectedTag();
          break;
      }
    }
  }

  move(direction, deleteCurrent): void {
    if (this.itemArray && this.itemArray.length > 0) {
      if (this.itemArray.length === 1) {
        if (deleteCurrent === true && this.itemArray[0].isTagSelected === true) {
          this.itemArray.splice(0, 1);

          return;
        }
        this.itemArray[0].isTagSelected = true;
      } else {
        if (direction === 1) {
          this.moveNext(deleteCurrent);
        } else if (direction === -1) {
          this.movePrevious(deleteCurrent);
        }
      }
    }
  }

  moveNext(deleteCurrent): void {
    for (let i = 0; i < this.itemArray.length; i++) {
      if (this.itemArray[i].isTagSelected === true) {
        if (deleteCurrent) {
          if (i === this.itemArray.length - 1) {
            this.itemArray[i - 1].isTagSelected = true;
          } else {
            this.itemArray[i + 1].isTagSelected = true;
          }
          this.itemArray.splice(i, 1);
        } else {
          if (i === this.itemArray.length - 1) {
            this.itemArray[0].isTagSelected = true;
          } else {
            this.itemArray[i + 1].isTagSelected = true;
          }
          this.itemArray[i].isTagSelected = false;
        }

        return;
      }
    }
    this.itemArray[0].isTagSelected = true;
  }

  movePrevious(deleteCurrent): void {
    for (let i = this.itemArray.length - 1; i >= 0; i--) {
      if (this.itemArray[i].isTagSelected === true) {
        if (deleteCurrent) {
          if (i === 0) {
            this.itemArray[i + 1].isTagSelected = true;
          } else {
            this.itemArray[i - 1].isTagSelected = true;
          }
          this.itemArray.splice(i, 1);
        } else {
          if (i === 0) {
            this.itemArray[this.itemArray.length - 1].isTagSelected = true;
          } else {
            this.itemArray[i - 1].isTagSelected = true;
          }
          this.itemArray[i].isTagSelected = false;
        }

        return;
      }
    }
    this.itemArray[this.itemArray.length - 1].isTagSelected = true;
  }

  clearSelectedTag(): void {
    if (this.itemArray && this.itemArray.length > 0) {
      for (let i = this.itemArray.length - 1; i >= 0; i--) {
        this.itemArray[i].isTagSelected = false;
      }
    }
  }

  onfocus(): void {
    this.hasFocus = true;
    if (!!this.includeRecent && !this.selectedItem && this.lastSearch !== this.text) {
      this.search(this.text, true);
    }
  }

  onblur = (argblur): void => {
    this.hasFocus = false;
    if (this.listClicked) {
      this.listClicked = false;

      argblur.target.focus();
    } else {
      if (!!this.control && !!this.control.control) {
        this.control.control.markAsTouched();
      }

      this.lastSearch = undefined;
      this.executeAction({
        type: 'input.blur'
      });
    }

    this.hasBlurred = true;
  };

  handleBlur(results: Array<any>): void {
    if (results.length) {
      this.changeState('idle');
      if (this.isMultiSelect) {
        if (this.autoComplete && (this.autoComplete.text === this.resultsFor || this.autoComplete.text === this.lastSearch)) {
          this.selectItem(results[0]);
        }
      } else {
        if (this.includeRecent && !this.text) {
            this.cdRef.detectChanges();
        } else {
            this.selectItem(results[0]);
        }
      }
    } else {
      this.changeState('invalid');
    }
    this.listClicked = false;
  }

  setSelectedRow(event): void {
    this.selectedItem = event;
    this.select(this.selectedItem);
    this.listClicked = true;
  }

  setListClicked(isClicked): void {
    this.listClicked = isClicked;
  }

  select(item): any {
    this.executeAction({
      type: 'item.select',
      value: item
    });
  }

  textChange(searchValue: string): void {
    if (!this.isMultiSelect) {
      this.selectedItem = null;
      this._onChange(this.selectedItem);
      this.text = searchValue;
      this.onChange.emit(this.text);
    }

    this.executeAction({
      type: 'text.change',
      value: this.text
    });
  }

  doSearch(value): any {
    if (this.state === 'idle') {
      return;
    }

    let params: any;
    params = {
      search: value === undefined ? '' : value,
      params: JSON.stringify({
        skip: 0,
        take: this.maxResults
      })
    };

    if (!!this.includeRecent) {
      params = { ...params, includeRecent: this.includeRecent };
    }

    if (this.extendQuery) {
      params = this.extendQuery(params);
    }

    this.callService = this.typeaheadService
      .getApiData(this.options.apiUrl, params)
      .subscribe((response: any) => {
        this.lastSearch = params.search;
        let mainResponse: any;
        let recentResults: any = null;
        if (!!response.data && !!response.data.resultsContainsRecent) {
          recentResults = response.data.recentResults != null ? response.data.recentResults.data : [];
          mainResponse = response.data.results;
        } else {
          mainResponse = response;
        }

        const results = mainResponse.data || mainResponse.data.data || [];

        const total = mainResponse.pagination
          ? mainResponse.pagination.total
          : results.length;

        if (!this.isMultiSelect) {
          this.selectedItem = null;
          if (results.length && !recentResults) {
            results[0].$selected = true;
          }
          if (!!recentResults && recentResults.length) {
            recentResults[0].$selected = true;
          }
          this._onChange(this.selectedItem);
        } else {
          this.markSelected(results);
        }

        this.executeAction({
          type: 'search.response',
          value: {
            recentResults,
            data: results,
            total
          }
        });
      });
  }

  markSelected(items): void {
    let k1;
    let k2;
    if (!_.any(this.itemArray) || items == null) {
      return;
    }

    _.each(items, (item: any) => {
      k1 = this.getKeyValue(item);
      const contains = _.any(this.itemArray, (item2: any) => {
        k2 = this.getKeyValue(item2);

        return k1 === k2;
      });

      if (contains) {
        item.$selected = true;
      }
    });
  }

  search(value: any, force: any): void {
    if (!value && !force) {
      this.changeState('idle');
      this.checkErrors();

      return;
    }
    this.setLoading(true);
    this.changeState('loading');
    this.doSearch(value);
    this.checkErrors();
  }

  executeAction(action): any {
    if (this.disabled) {
      return;
    }
    this.checkState(action);
  }

  handleIdle(action): void {
    switch (action.type) {
      case 'text.change':
        this.search(this.text, false);
        break;
      case 'key.down':
        this.search(this.text, true);
        break;
      default:
        break;
    }
  }
  handleLoading(action): void {
    switch (action.type) {
      case 'text.change':
        this.search(this.text, false);
        break;
      case 'search.response':
        this.setLoading(false);
        const results = action.value.data;
        const total = action.value.total;
        const recentResults = action.value.recentResults;
        if (this.hasFocus) {
          this.changeState('loaded');
          this.recentResults = recentResults;
          this.results = results;
          this.total = total;
          this.cdRef.markForCheck();
        } else {
          this.handleBlur(!!recentResults ? recentResults : results);
        }
        break;
      case 'key.esc':
        this.setLoading(false);
        this.changeState('cancelled');
        break;
      case 'input.blur':
        this.setLoading(false);
        this.results = null;
        this.recentResults = null;
        break;
      default:
        break;
    }
  }

  handleLoaded(action): void {
    switch (action.type) {
      case 'text.change':
        this.search(this.text, false);
        break;
      case 'item.select':
        this.selectItem(action.value);
        this.changeState('idle');
        break;
      case 'key.esc':
        this.changeState('cancelled');
        break;
      case 'input.blur':
        if (!this.text) {
          this.changeState('idle');
        } else {
          this.handleBlur(!!this.recentResults ? this.recentResults : this.results);
        }
        break;
      default:
        break;
    }
  }

  checkState(action): void {
    switch (this.state) {
      case 'idle': this.handleIdle(action);
        break;
      case 'loading': this.handleLoading(action);
        break;
      case 'loaded': this.handleLoaded(action);
        break;
      case 'cancelled':
        switch (action.type) {
          case 'text.change':
          case 'key.down':
          case 'input.blur':
            this.search(this.text, false);
            break;
          default:
            break;
        }
        break;
      case 'invalid':
        switch (action.type) {
          case 'text.change':
          case 'key.down':
            this.search(this.text, false);
            break;
          default:
            break;
        }
        break;
      default:
        break;
    }
  }

  selectItem(item, hasPicklistModelOpened = false): void {
    if (this.isMultiSelect) {
      this.addItem(item);
      this.text = '';
      this.adjustMultiSelectInputWidth();
      if (!hasPicklistModelOpened) {
        this._onChange(this.itemArray);
        this.onChange.emit(this.itemArray);
      }
    } else {
      const k1 = this.getKeyValue(this.selectedItem);
      const k2 = this.getKeyValue(item);

      if (k1 !== k2) {
        this.selectedItem = item;
      }

      this.text = this.getDisplayValue(this.selectedItem);
      this.displayText = this.options && this.options.showDisplayField ? this.getDisplayText(this.selectedItem) : this.text;
      this._onChange(this.selectedItem);
      this.onChange.emit(this.selectedItem);
    }
    this.cdRef.markForCheck();
    this.results = null;
    this.recentResults = null;
  }

  addItem(item): void {
    const selectedItems: any = this.getSelectedItems() || [];
    const exists: Boolean = _.some(
      selectedItems,
      (a: any) => item[this.options.keyField] === a[this.options.keyField]
    );

    if (!exists) {
      const newItems: any = selectedItems.slice(0);
      newItems.push(item);
      this.itemArray = newItems;
      this._onChange(this.itemArray);
      this.adjustMultiSelectInputWidth();
    }
  }

  adjustMultiSelectInputWidth = (): void => {
    const minWidth = 50;
    const element = this.el.nativeElement;
    setTimeout(() => {
      const input = element.querySelector('input.typeahead');
      this.renderer.setStyle(input, 'width', minWidth.toString() + 'px');
      const container = element.querySelector('.tags'); // width with padding
      const tags = element.querySelectorAll('.label-tag');
      const lastTag = tags[tags.length - 1];

      if (lastTag) {
        const width = container.width() -
          (lastTag.getBoundingClientRect().left - container.getBoundingClientRect().left
            + lastTag.getBoundingClientRect().width);
        this.renderer.setStyle(input, 'width', (width < minWidth ? '100%' : width.toString() + 'px'));
      } else {
        this.renderer.setStyle(input, 'width', '100%');
      }
    }, 10);
  };

  removeItem(item): void {
    const selectedItems = this.getSelectedItems();
    const newItems = _.without(selectedItems, item);

    this.itemArray = newItems;
    this._onChange(this.itemArray);
    this.onChange.emit(this.itemArray);
    this.adjustMultiSelectInputWidth();
    this.checkErrors();
    this.el.nativeElement.querySelector('input.typeahead').focus();
  }

  getDisplayValue(item): any {

    return (!!item && !!this.options) ? item[this.options.textField] === '' ? item[this.options.codeField] : item[this.options.textField] : null;
  }

  getDisplayText(item): any {
    if (item[this.options.textField] == null || item[this.options.textField] === undefined && item[this.options.codeField] !== null) {
      this.text = item[this.options.codeField];
    }

    return item && item[this.options.codeField] ? '(' + item[this.options.codeField] + ') ' + (item[this.options.textField] == null ? '' : item[this.options.textField]) : '';
  }

  getKeyValue(item): any {
    const itemKeyValue = item && item[this.options.keyField];

    return _.isUndefined(itemKeyValue) ? undefined : itemKeyValue;
  }

  setLoading(isLoading): void {
    this.loading = Boolean(isLoading);
  }

  changeState(state): void {
    switch (state) {
      case 'idle':
        this.results = null;
        this.recentResults = null;
        this.state = state;
        this.setLoading(false);
        break;
      case 'cancelled':
        this.results = null;
        this.recentResults = null;
        this.state = state;
        if (!this.text) {
          this.state = 'idle';
        }
        break;
      case 'loading':
        this.state = state;
        break;
      case 'loaded':
        this.state = state;
        break;
      case 'invalid':
        this.checkErrors();
        this.results = null;
        this.recentResults = null;
        this.state = state;
        break;
      case 'modal':
        this.results = null;
        this.recentResults = null;
        this.state = state;
        break;
      default:
        break;
    }
  }

  checkErrors = (): any => {
    if (this.text && !_.any(this.results) && !this.loading) {
      this.control.control.setErrors({ invalidentry: true });
      this.control.control.markAsDirty();
      this.cdRef.markForCheck();
    } else if (this.showTagsError && this.itemArray.some(x => x.isError) && !this.tagsErrorValidator.applyOnChange) {
      this.control.control.setErrors(this.tagsErrorValidator.validator);
    } else {
      this.control.control.setErrors({});
      this.control.control.updateValueAndValidity();
    }
  };

  getError = () => {
    if (!this.control) {
      return [];
    }

    const { errors } = this.control.control;

    if (!errors) {
      this.resetItemsArray();

      return null;
    }
    const err = Object.keys(errors).map(key => {
      if (this.showTagsError && errors[key] === 'duplicate') {

        return this.getTagsError(errors.errorObj) ? 'field.errors.' + key : null;
      }
      if (key === 'invalidentry' && errors[key] && this.notFoundError) {

          return 'field.errors.' + this.notFoundError;
      }

      return 'field.errors.' + key;
    });

    return this.showError() && err.length > 0 ? err[0] : '';
  };
  isStable = (): boolean => {
    return (!this.results || this.results.length === 0) && !this.loading;
  };

  getTagsError(errorObj: TagsErrorValidator): boolean {
    let error = false;
    this.resetItemsArray();
    if (this.isMultiSelect && errorObj && errorObj.keys) {
      this.tagsErrorValidator = errorObj;
      this.itemArray.forEach(x => {
        if (errorObj.keys.some(p => p === x[errorObj.keysType])) {
          x.isError = true;
          error = true;
        }

      });
    } else if (!this.isMultiSelect && errorObj) {
      this.tagsErrorValidator = errorObj;
      this.selectedItem.isError = true;
      error = true;

    } else if (!this.tagsErrorValidator.applyOnChange) {

      return this.tagsErrorValidator.validator ? true : null;
    } else {
      this.resetItemsArray();
      this.control.control.setErrors(null);
    }
    this.cdRef.markForCheck();

    return error;
  }

  private resetItemsArray(): void {
    if (this.tagsErrorValidator && this.tagsErrorValidator.applyOnChange) {
      this.itemArray.forEach(x => {
        x.isError = false;
      });
    }
  }
}
