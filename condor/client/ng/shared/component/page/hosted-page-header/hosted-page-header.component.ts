import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { takeUntil } from 'rxjs/operators';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';

@Component({
  selector: 'app-hosted-page-header',
  templateUrl: './hosted-page-header.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})

export class HostedPageHeaderComponent implements OnInit {

  @Input() type: 'search' | 'save';
  @Input() position: 'top' | 'bottom';
  @Input() disabled: boolean;
  @Input() viewData;
  @Input() hostedMenuOptions: Array<any>;
  @Input() useDefaultPresentation: Boolean;
  @Input() userHasDefaultPresentation: Boolean;
  @Input() addShortcuts: Boolean;
  @Output() readonly onAction = new EventEmitter<'save' | 'cancel' | 'search'>();
  @Output() readonly onRevert = new EventEmitter<any>();

  isHosted = false;
  headerStyle = {};
  constructor(rootscopeService: RootScopeService,
    private readonly shortcutsService: IpxShortcutsService,
    private readonly destroy$: IpxDestroy) {
    this.isHosted = rootscopeService.isHosted;
  }
  ngOnInit(): void {
    switch (this.position) {
      case 'bottom':
        this.headerStyle = {
          'margin-bottom': '8px'
        };
        break;
      default:
        this.headerStyle = {};
        break;
    }

    if (!!this.addShortcuts) {
      this.handleShortcuts();
    }
  }

  executeAction = (cmd: 'save' | 'cancel' | 'search'): void => {
    this.onAction.emit(cmd);
  };

  revert = () => {
    this.onRevert.emit('');
  };

  initializeMenuItems = () => {
    const makeDefaultMenuOption = _.first(this.hostedMenuOptions);
    makeDefaultMenuOption.disabled = this.useDefaultPresentation;
    const revertToDefaultMenuOption = _.last(this.hostedMenuOptions);
    revertToDefaultMenuOption.disabled = !this.userHasDefaultPresentation;
  };

  handleShortcuts(): void {
    const shortcutCallbacksMap = new Map(
      [[RegisterableShortcuts.REVERT, (): void => { this.revert(); }],
      [RegisterableShortcuts.SAVE, (): void => { this.executeAction('save'); }]]);
    this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
      .pipe(takeUntil(this.destroy$))
      .subscribe((key: RegisterableShortcuts) => {
        if (!!key && shortcutCallbacksMap.has(key) && !this.disabled) {
          shortcutCallbacksMap.get(key)();
        }
      });
  }
}