import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { AppContextService } from 'core/app-context.service';
import { LocalSettings } from 'core/local-settings';
import { QuickNavModel, QuickNavModelOptions } from 'rightbarnav/rightbarnav.service';
import { Subject } from 'rxjs';

export interface IHomePageService {
    init(model: QuickNavModel): void;
    setHomePage(): void;
    isCurrentPageHomePage(): boolean;
    setIconState(): void;
}

@Injectable()
export class HomePageService implements IHomePageService {
    homePageStateKey = 'homePageState';
    current: QuickNavModelOptions;
    currentSavedPage: any;
    iconStateChange = new Subject();

    constructor(public localSettings: LocalSettings, public stateService: StateService, private readonly httpClient: HttpClient, private readonly appContext: AppContextService, private readonly notificationService: NotificationService) {
    }

    init(model: QuickNavModel): void {
        this.current = model.options;
        this.current.icon = 'mark-favorite';
        this.current.tooltip = 'quicknav.setAsHomePage';
        this.current.click = this.setHomePage;
    }

    setHomePage = (): void => {
        if (this.isCurrentPageHomePage()) {
            this.httpClient.delete('api/portal/home/reset').subscribe(() => {
                this.currentSavedPage = null;
                this.appContext.resetHomePageState();
                this.setIconState();
                this.notificationService.success('userPreferences.homePage.reset');
            });
        } else {
            const currentPage = { name: this.stateService.$current.name, params: this.stateService.params };
            this.httpClient.put('api/portal/home/set', currentPage).subscribe(() => {
                this.currentSavedPage = currentPage;
                this.appContext.setHomePageState(currentPage);
                this.setIconState();
                this.notificationService.success('userPreferences.homePage.saved');
            });
        }
    };

    isCurrentPageHomePage = (): boolean => {
        const currentPage = this.stateService.$current.name;
        if (this.currentSavedPage != null && currentPage === this.currentSavedPage.name) {
            return true;
        }

        return false;
    };

    setIconState = (): void => {
        if (this.isCurrentPageHomePage()) {
            this.current.icon = 'mark-favorite marked-favorite';
            this.current.tooltip = 'quicknav.alreadySetAsHomePage';
        } else {
            this.current.icon = 'mark-favorite';
            this.current.tooltip = 'quicknav.setAsHomePage';
        }
        this.iconStateChange.next();
    };
}
