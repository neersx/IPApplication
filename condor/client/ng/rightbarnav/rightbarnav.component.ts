import { ChangeDetectionStrategy, ChangeDetectorRef, Component, NgZone, OnDestroy, OnInit, ViewChild, ViewContainerRef } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { TransitionService } from '@uirouter/core';
import { Hotkey, HotkeysService } from 'angular2-hotkeys';
import { AppContextService } from 'core/app-context.service';
import { MessageBroker } from 'core/message-broker';
import { BsModalRef, BsModalService } from 'ngx-bootstrap/modal';
import { Subscription } from 'rxjs/internal/Subscription';
import { take } from 'rxjs/operators';
import * as _ from 'underscore';
import { BackgroundNotificationComponent } from './background-notification/background-notification.component';
import { BackgroundNotificationService } from './background-notification/background-notification.service';
import { HelpComponent } from './help/help.component';
import { HomePageService } from './homepage/homepage.service';
import { KotModel } from './keepontopnotes/keep-on-top-notes-models';
import { KeyboardShortcutCheatSheetComponent } from './keyboardshortcutcheatsheet/keyboardshortcutcheatsheet.component';
import { LinksComponent } from './links/links.component';
import {
  IQuickNavList,
  QuickNavModel,
  QuickNavModelOptions,
  RightBarNavService
} from './rightbarnav.service';
import { RightBarNavLoaderService } from './rightbarnavloader.service';
import { UserInfoComponent } from './userinfo/userinfo.component';

@Component({
  selector: 'rightbarnav',
  templateUrl: './rightbarnav.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RightBarNavComponent implements OnInit, OnDestroy {

  isOpened: boolean;
  active: any;
  defaults: any;
  contextual: any;
  modalRef: BsModalRef;
  backgroundMessageCount = 0;
  backgroundNotification: QuickNavModel;
  appContext: any;
  hasKot: boolean;
  kotActive: boolean;
  kotNotes: Array<KotModel> | null;
  kotNotesCount: number;
  homeIconSubscription: Subscription;

  @ViewChild('dynamiccontentbody', { read: ViewContainerRef, static: true }) viewContainerRef: ViewContainerRef;

  ngOnInit(): void {
    this.subscribeOnCloseEvent();
    this.rightBarNavLoaderService.setRootViewContainerRef(this.viewContainerRef);

    this.registerDefault();
    this.defaults = this.service.getDefault();

    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe(ctx => {
        this.appContext = ctx;
        this.subscribeToBackGroundNotification(ctx.user.identityId);
      });

    this.homeIconSubscription = this.homepageService.iconStateChange.subscribe(() => {
      this.cdref.detectChanges();
    });
  }

  constructor(public service: RightBarNavService,
    public rightBarNavLoaderService: RightBarNavLoaderService,
    private readonly hotkeysService: HotkeysService,
    private readonly transitionService: TransitionService,
    private readonly appContextService: AppContextService,
    private readonly homepageService: HomePageService,
    private readonly cdref: ChangeDetectorRef,
    private readonly modalService: BsModalService,
    private readonly messageBroker: MessageBroker,
    private readonly translate: TranslateService,
    private readonly backgroundNotificationService: BackgroundNotificationService,
    private readonly zone: NgZone,
    private readonly rightBarNavService: RightBarNavService) {
    this.active = null;
    this.isOpened = false;
    const addNavigationItem = (key: string, item: QuickNavModel) => {
      if (item.options.shortcutCombo) {

        this.hotkeysService.add(new Hotkey(item.options.shortcutCombo, (): boolean => {

          item.options.click();

          return false;
        }, undefined, item.options.tooltip));
      }
    };

    const addContextList = (contextualItems: IQuickNavList | null | undefined): void => {
      this.contextual = contextualItems;
      this.cdref.detectChanges();
    };

    const addKotPanel = (kotNotes: Array<KotModel> | null | undefined): void => {
      this.hasKot = kotNotes && kotNotes.length > 0;
      this.kotNotes = this.hasKot ? kotNotes : null;
      this.kotNotesCount = kotNotes ? kotNotes.length : 0;
      this.kotActive = this.hasKot;
      this.cdref.detectChanges();
    };

    service.onAdd(addNavigationItem);
    service.onAddContextual(addContextList);
    service.onAddKot(addKotPanel);

    for (const key in this.defaults) {
      if (this.defaults.hasOwnProperty(key)) {
        addNavigationItem(key, this.defaults[key]);
      }
    }

    this.transitionService.onSuccess({}, (trans) => {
      const toState = trans.to();
      if (!toState.data || !toState.data.hasContextNavigation) {
        service.registercontextuals(undefined);
      }
      service.registerKot(undefined);
      this.kotActive = false;
      this.appContextService.appContext$
        .pipe(take(1))
        .subscribe((ctx) => {
          this.homepageService.currentSavedPage = ctx.user.preferences.homePageState;
          this.homepageService.setIconState();
          this.cdref.detectChanges();
        });
    });
  }

  private readonly subscribeOnCloseEvent = () => {
    this.rightBarNavService.onCloseRightBarNav$.subscribe(close => {
      if (close) {
        this.close();
      }
    });
  };

  private readonly subscribeToBackGroundNotification = (identityId: number) => {
    this.messageBroker.subscribe('background.notification.' + identityId, (processIds) => {
      this.zone.runOutsideAngular(() => {
        this.backgroundNotificationService.setProcessIds(processIds);
        this.backgroundMessageCount = processIds.length;
        this.backgroundNotification.options.title = this.translate.instant('quicknav.notification.title') + (this.backgroundMessageCount > 0 ? ' (' + this.backgroundMessageCount + ')' : '');
        this.cdref.detectChanges();
      });
    });

    this.messageBroker.connect();
  };

  ngOnDestroy(): void {
    this.messageBroker.disconnect();
    this.homeIconSubscription.unsubscribe();
  }

  hasBackgroundMessage = (): boolean => {
    return this.backgroundMessageCount > 0;
  };

  private readonly registerDefault = () => {

    this.service.registerDefault('userinfo', new QuickNavModel(UserInfoComponent, { id: 'userinfo', icon: 'cpa-icon-user' }));

    const notificationOption = new QuickNavModelOptions();
    notificationOption.id = 'backgroundNotification';
    notificationOption.icon = 'cpa-icon-comment';
    notificationOption.title = 'quicknav.notification.title';
    notificationOption.tooltip = 'quicknav.notification.title';
    notificationOption.callBack = this.close;
    this.backgroundNotification = this.service.registerDefault('backgroundNotification', new QuickNavModel(BackgroundNotificationComponent, notificationOption));

    const cheatSheetoption = new QuickNavModelOptions();
    cheatSheetoption.id = 'cheatSheet';
    cheatSheetoption.icon = 'cpa-icon-keyboard';
    cheatSheetoption.tooltip = 'keyboardShortcuts.displayShortcuts';
    cheatSheetoption.shortcutCombo = 'alt+shift+\/';
    cheatSheetoption.click = this.openCheatSheet;
    this.service.registerDefault('cheatSheet', new QuickNavModel(null, cheatSheetoption));

    this.homepageService.init(this.service.registerDefault('setAsHomePage', new QuickNavModel(null, null)));
    this.service.registerDefault('help', new QuickNavModel(HelpComponent, { id: 'help', icon: 'cpa-icon-inline-help' }));
    this.service.registerDefault('links', new QuickNavModel(LinksComponent, { id: 'links', icon: 'cpa-icon-globe' }));

    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe(ctx => {
        if (!ctx.isWindowsAuthOnly) {
          const options = new QuickNavModelOptions();
          options.id = 'logout';
          options.icon = 'cpa-icon-sign-out';
          options.tooltip = 'quicknav.logout.tooltip';
          options.click = (): void => {
            localStorage.setItem('signin', '{}');
            window.location.href = 'api/signout';
          };
          this.service.registerDefault('logout', new QuickNavModel(null, options));
        }
      });
  };

  openCheatSheet = (): any => {
    if (this.modalRef) { return; }
    this.modalRef = this.modalService.show(KeyboardShortcutCheatSheetComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg'
    });
    this.modalService.onHide
      .subscribe(() => {
        this.modalRef = null;
      });

    return this.modalRef;
  };

  asIsOrder = () => {
    return 1;
  };

  btn = (index, item) => {
    return item;
  };

  openSlider = (id: string, contextual?: boolean) => {
    if (!id || this.isActive(id)) {
      return;
    }

    this.isOpened = true;
    this.active = contextual ? this.contextual[id] : this.defaults[id];
    this.rightBarNavLoaderService.load(this.active);
  };

  close = () => {
    this.isOpened = false;
    this.active = null;
    this.rightBarNavLoaderService.remove();
  };

  isActive = (id: string): boolean => {
    if (id && this.active && this.active.options && this.active.options.id === id) {
      return true;
    }

    return false;
  };

  click = (options: any, contextual?: boolean): void => {
    const c = options.click || this.openSlider;
    c(options.id, contextual);
  };

  kotChange = (): void => {
    this.kotActive = !this.kotActive;
  };
}