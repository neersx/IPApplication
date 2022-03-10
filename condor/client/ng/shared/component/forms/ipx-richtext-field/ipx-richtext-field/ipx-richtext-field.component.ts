import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnDestroy, OnInit, Optional, Self, ViewChild } from '@angular/core';
import { NgControl } from '@angular/forms';
import { QuillEditorComponent } from 'ngx-quill';
import { Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, first } from 'rxjs/operators';
import { ElementBaseComponent } from '../../element-base.component';

@Component({
  selector: 'ipx-richtext-field',
  templateUrl: './ipx-richtext-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxRichtextFieldComponent extends ElementBaseComponent<string> implements OnInit, AfterViewInit, OnDestroy {

  @Input() label: string;
  @Input() rows: number | undefined;
  @Input() placeholder: string;
  @Input() errorParam: any;
  @Input() allowRichText: boolean;

  identifier: string;
  @ViewChild('editor') private readonly editor: QuillEditorComponent;
  private editorParentDiv: any;
  private subscriptions: Array<Subscription>;

  ngOnInit(): any {
    this.subscriptions = new Array<Subscription>();
    this.identifier = this.getId('richtextfield');

    if (this.rows === undefined) {
      this.rows = 3;
    }
  }

  constructor(
    readonly elementRef: ElementRef,
    readonly cdRef: ChangeDetectorRef,
    @Self() @Optional() public control: NgControl
  ) {
    super(control, elementRef, cdRef);
  }

  ngAfterViewInit(): void {
    if (this.allowRichText) {
      this.editorParentDiv = this.elementRef.nativeElement.querySelector('.input-wrap');
      this.registerQuillEvents();
    }
  }

  getCustomErrorParams = () => ({
    errorParam: this.errorParam
  });

  onKeyup = (event: any) => {
    this._onChange(event.target ? event.target.value : null);
  };

  getQuillEditorOptions = (): any => {

    return {
      toolbar: [
        ['bold', 'italic', 'underline', 'strike'],
        ['blockquote', 'code-block'],

        [{ header: 1 }, { header: 2 }],
        [{ list: 'ordered' }, { list: 'bullet' }],
        [{ script: 'sub' }, { script: 'super' }],
        [{ indent: '-1' }, { indent: '+1' }],
        [{ direction: 'rtl' }],

        [{ header: [1, 2, 3, 4, 5, 6, false] }],

        [{ color: [] }, { background: [] }],
        [{ align: [] }],

        ['clean']
      ]
    };
  };

  registerQuillEvents = (): void => {
    this.subscriptions.push(this.editor
      .onContentChanged
      .pipe(
        debounceTime(400),
        distinctUntilChanged()
      )
      .subscribe((data) => {
        this._onChange(data.html);
      })
    );

    this.subscriptions.push(this.editor
      .onFocus
      .subscribe((data) => {
        this.touch();
        this.editorParentDiv.classList.add('input-wrap-focus');
      }));

    this.subscriptions.push(this.editor
      .onBlur
      .subscribe((data) => {
        this.blur();
        this.editorParentDiv.classList.remove('input-wrap-focus');
      }));
  };

  ngOnDestroy(): void {
    this.subscriptions.forEach(subscription => subscription.unsubscribe());
  }
}
