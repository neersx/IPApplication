import { ChangeDetectionStrategy, Component, Input, OnInit, TemplateRef } from '@angular/core';

@Component({
  selector: 'ipx-inline-dialog',
  templateUrl: './ipx-inline-dialog.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxInlineDialogComponent implements OnInit {
  @Input() templateRef: TemplateRef<any>;
  @Input() title: string;
  @Input() content: string;
  @Input() tooltipPlacement: string;
  @Input() icon = 'cpa-icon cpa-icon-question-circle';
  tooltipContent: any;
  @Input() adaptivePosition = false;
  @Input() container: string;
  @Input() size = 'lg';
  @Input() colorStyle: any;

  ngOnInit(): void {
    this.tooltipContent = this.content || this.templateRef;
  }
}