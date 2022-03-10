import { ChangeDetectionStrategy, Component, EventEmitter, HostListener, Input, OnInit, Output, ViewChild } from '@angular/core';
import { LocalSetting } from 'core/local-settings';

@Component({
  selector: 'ipx-widget-frame',
  templateUrl: './ipx-widget-frame.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxWidgetFrameComponent implements OnInit {
  expanded;
  @Input() title: string;
  @Input() expandSetting: LocalSetting;
  @Input() autoFit: boolean;
  @Output() readonly propagateChange = new EventEmitter<any>();
  @ViewChild('widgetBody') private readonly widgetBody;

  ngOnInit(): void {
    if (this.expandSetting && this.expandSetting.getLocal) {
      this.expand();
    }
  }

  @HostListener('window:resize', ['$event']) toggleHeight(event): void {
    if (!this.expanded) {
      this.makeHalfHeight();
    }
  }
  expand(): void {
    this.expanded = true;
    this.makeFullHeight();
    if (this.expandSetting && !(this.expandSetting.getLocal)) {
      this.expandSetting.setLocal(true);
    }
  }

  restore(): void {
    this.expanded = false;
    if (!this.autoFit) {
      this.makeHalfHeight();
    } else {
      this.height = '';
      this.propagateChange.emit(this.height);
    }

    if (this.expandSetting && (this.expandSetting.getLocal)) {
      this.expandSetting.setLocal(false);
    }
  }

  makeFullHeight(): void {
    this.height = '100vh';
    this.propagateChange.emit(this.height);
  }

  height: string;
  makeHalfHeight(): void {
    const height = 1000;
    this.height = (height - 70) / 2 + 'px';
  }
}
