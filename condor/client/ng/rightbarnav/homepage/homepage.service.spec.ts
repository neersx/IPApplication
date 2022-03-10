import { AppContextServiceMock } from 'core/app-context.service.mock';
import { HttpClientMock, LocalSettingsMocks, NotificationServiceMock, StateServiceMock } from 'mocks';
import { QuickNavModel, QuickNavModelOptions } from 'rightbarnav/rightbarnav.service';
import { of } from 'rxjs';
import { HomePageService } from './homepage.service';

describe('HomepageService', () => {
    let homepageService: HomePageService;
    const localSettings = new LocalSettingsMocks();
    const stateService = new StateServiceMock();
    const httpClient = new HttpClientMock();
    const appContext = new AppContextServiceMock();
    const notificationService = new NotificationServiceMock();
    beforeEach((() => {
        httpClient.put = jest.fn().mockReturnValue(of({}));
        httpClient.delete = jest.fn().mockReturnValue(of({}));
        homepageService = new HomePageService(localSettings as any, stateService as any, httpClient as any, appContext as any, notificationService as any);
        homepageService.current = new QuickNavModelOptions();
    }));

    it('should be created', () => {
        expect(homepageService).toBeTruthy();
    });

    it('Validate init', () => {
        const model = new QuickNavModel(null, new QuickNavModelOptions());
        homepageService.init(model);
        expect(homepageService).toBeDefined();
        expect(homepageService.current.icon).toBe('mark-favorite');
        expect(homepageService.current.tooltip).toBe('quicknav.setAsHomePage');
        expect(homepageService.current.click).toBe(homepageService.setHomePage);
    });

    describe('Setting the home page', () => {
        beforeEach(() => {
            homepageService.setIconState = jest.fn();
        });
        it('saves home page preference if not set', (done) => {
            homepageService.setHomePage();
            expect(httpClient.put.mock.calls[0][0]).toBe('api/portal/home/set');
            expect(httpClient.put.mock.calls[0][1]).toEqual(expect.objectContaining({ name: stateService.$current.name, params: stateService.params }));
            httpClient.put().subscribe(() => {
                expect(homepageService.currentSavedPage).toEqual(expect.objectContaining({ name: stateService.$current.name, params: stateService.params }));
                expect(homepageService.setIconState).toHaveBeenCalled();
                expect(appContext.setHomePageState.mock.calls[0][0]).toEqual(homepageService.currentSavedPage);
                expect(notificationService.success).toHaveBeenCalledWith('userPreferences.homePage.saved');
                done();
            });
        });

        it('resets home page preference when user is on same page as home', (done) => {
            homepageService.currentSavedPage = { name: stateService.$current.name, params: stateService.params };
            homepageService.setHomePage();
            expect(httpClient.delete).toHaveBeenCalled();
            expect(httpClient.delete.mock.calls[0][0]).toBe('api/portal/home/reset');
            httpClient.delete().subscribe(() => {
                expect(homepageService.currentSavedPage).toBeNull();
                expect(homepageService.setIconState).toHaveBeenCalled();
                expect(appContext.resetHomePageState).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalledWith('userPreferences.homePage.reset');
                done();
            });
        });
    });

    it('Validate isCurrentPageHomePage', () => {
        const result = homepageService.isCurrentPageHomePage();
        expect(result).toBeFalsy();
    });

    describe('Setting icon state', () => {
        beforeEach(() => {
            spyOn(homepageService.iconStateChange, 'next');
        });
        it('sets saved state', () => {
            homepageService.currentSavedPage = { name: stateService.$current.name, params: stateService.params };
            homepageService.setIconState();
            expect(homepageService.current.icon).toBe('mark-favorite marked-favorite');
            expect(homepageService.iconStateChange.next).toHaveBeenCalled();
        });
        it('resets state', () => {
            homepageService.setIconState();
            expect(homepageService.current.icon).toBe('mark-favorite');
            expect(homepageService.iconStateChange.next).toHaveBeenCalled();
        });
    });
});
