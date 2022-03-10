import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock, MessageBroker, NgZoneMock, TranslateServiceMock } from 'mocks';
import { KeyBoardShortCutServiceMock } from 'mocks/keyboardshortcutservice.mock';
import { HomePageServiceMock } from 'rightbarnav/homepage/homepageservice.mock';
import { BsModalServiceMock } from './../mocks/bs-modal.service.mock';
import { BackgroundNotificationServiceMock } from './background-notification/background-notification.service.mock';
import { RightBarNavComponent } from './rightbarnav.component';
import { RightBarNavLoaderServiceMock } from './rightbarnavloaderservice.mock';
import { RightBarNavServiceMock } from './rightbarnavservice.mock';

describe('RightBarNavComponent', () => {
    let component: RightBarNavComponent;
    const rightBarNavServiceMock = new RightBarNavServiceMock();
    const rightBarNavLoaderServiceMock = new RightBarNavLoaderServiceMock();
    const keyBoardShortCutServiceMock = new KeyBoardShortCutServiceMock();
    const transitionServiceMock = new TranslateServiceMock();
    const appContextServiceMock = new AppContextServiceMock();
    const homePageServiceMock = new HomePageServiceMock();
    const changeDetectorRefMock = new ChangeDetectorRefMock();
    const bsModalServiceMock = new BsModalServiceMock();
    const messageBrokerMock = new MessageBroker();
    const backgroundNotificationServiceMock = new BackgroundNotificationServiceMock();
    const zone = new NgZoneMock();
    const rightBarNav = new RightBarNavServiceMock();

    beforeEach(() => {
        component = new RightBarNavComponent(rightBarNavServiceMock as any,
            rightBarNavLoaderServiceMock as any,
            keyBoardShortCutServiceMock as any,
            transitionServiceMock as any,
            appContextServiceMock as any,
            homePageServiceMock as any,
            changeDetectorRefMock as any,
            bsModalServiceMock as any,
            messageBrokerMock as any,
            transitionServiceMock as any,
            backgroundNotificationServiceMock as any,
            zone as any,
            rightBarNav as any
        );
        component.defaults = {};
        component.contextual = {};
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('validate close method', () => {
        component.close();
        expect(component).toBeDefined();
    });

    it('validate isActive method', () => {
        const result = component.isActive('userinfo');
        expect(result).toEqual(false);
    });

    it('validate close method', () => {
        const options = {
            id: 'help',
            icon: 'cpa-icon-inline-help',
            title: 'quicknav.help.title',
            tooltip: 'quicknav.help.tooltip'
        };
        component.click(options, false);
        expect(component).toBeDefined();
    });

    it('validate openSlider method', () => {
        component.openSlider('userinfo', false);
        expect(component).toBeDefined();
    });
    it('validate kotonchange method', () => {
        component.kotActive = false;
        component.kotChange();
        expect(component.kotActive).toBe(true);
    });
});
