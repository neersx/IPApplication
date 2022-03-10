import { fakeAsync, tick } from '@angular/core/testing';
import { BsModalRefMock, ChangeDetectorRefMock, LocalSettingsMocks } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { UserInfoServiceMock } from '../time-recording.mock';
import { PostSelectedComponent } from './post-selected/post-selected.component';
import { PostTimeComponent } from './post-time.component';
import { PostTimeView } from './post-time.model';

describe('PostTimeComponent', () => {
    let c: PostTimeComponent;
    let postTimeService: any;
    let modalService: ModalServiceMock;
    let cdRef: any;
    let modalRef: BsModalRefMock;
    let localSettings: any;
    let userInfo: any;

    beforeEach(() => {
        postTimeService = { postTime: jest.fn(), disablePostBtnSubj: of(true), postSelectedEntry: jest.fn(), getview: jest.fn(), postForAllStaff: jest.fn() };
        modalService = new ModalServiceMock();
        cdRef = new ChangeDetectorRefMock();
        modalRef = new BsModalRefMock();
        modalRef.hide = jest.fn();
        localSettings = new LocalSettingsMocks();
        userInfo = new UserInfoServiceMock();
        c = new PostTimeComponent(modalRef, postTimeService, cdRef, localSettings, userInfo);
    });

    describe('Initialize', () => {
        let view: PostTimeView;
        beforeEach(() => {
            view = {
                hasFixedEntity: true,
                postToCaseOfficeEntity: true
            } as any as PostTimeView;
        });
        it('should default the dropdown to one that has the default flag set when there is more than 1 entity', () => {
            view.entities = [{ id: 1, displayName: 'Entity1', isDefault: false }, { id: 2, displayName: 'Entity2', isDefault: true }, { id: 3, displayName: 'Entity3', isDefault: false }];
            postTimeService.getView = jest.fn().mockReturnValue(of(view));

            c.ngOnInit();
            c.view$.subscribe();

            expect(c.selectedEntityKey).toBe(2);
        });
        it('should set the postEntry entity key to the selected key', () => {
            c.postEntryDetails = { entryNo: 1 };
            view.entities = [{ id: 1, displayName: 'Entity1', isDefault: false }, { id: 2, displayName: 'Entity2', isDefault: true }, { id: 3, displayName: 'Entity3', isDefault: false }];
            postTimeService.getView = jest.fn().mockReturnValue(of(view));

            c.ngOnInit();
            c.view$.subscribe();

            expect(c.postEntryDetails.entityKey).toBe(2);
        });
        it('should default the dropdown to the entity when the view has only one entity', () => {
            view.entities = [{ id: 999, displayName: 'Entity1', isDefault: false }];
            postTimeService.getView = jest.fn().mockReturnValue(of(view));
            c.ngOnInit();
            c.view$.subscribe();

            expect(c.selectedEntityKey).toBe(999);
        });
        it('should not set a selected entity if there are none available', () => {
            view.entities = null;
            postTimeService.getView = jest.fn().mockReturnValue(of(view));
            c.ngOnInit();
            c.view$.subscribe();

            expect(c.selectedEntity).toBeUndefined();
            expect(c.selectedEntityKey).toBeUndefined();
        });
        it('should set the flags', () => {
            view.entities = null;
            postTimeService.getView = jest.fn().mockReturnValue(of(view));
            c.ngOnInit();
            c.view$.subscribe();

            expect(c.isEntityDisabled).toBe(true);
            expect(c.isEntityHidden).toBe(true);
        });
        it('should initialise the post for all staff fields', () => {
            c.canPostForAllStaff = true;
            c.currentDate = new Date();
            c.ngAfterViewInit();

            expect(c.postAllStaff).toBeFalsy();
            expect(c.postAllStaffFromDate.getDate()).toEqual(c.currentDate.getDate());
            expect(c.postAllStaffToDate.getDate()).toEqual(c.currentDate.getDate());
        });
    });

    describe('Post time', () => {
        beforeEach(() => {
            const view = {
                entities: [{ id: 123, displayName: 'Entity123', isDefault: false }, { id: 999, displayName: 'Entity999', isDefault: true }],
                hasFixedEntity: false,
                postToCaseOfficeEntity: false
            };
            postTimeService.getView = jest.fn().mockReturnValue(of(view));
            c._postSelectedRef = {} as any as PostSelectedComponent;
            c._postSelectedRef.getSelectedDates = jest.fn();
            c._postSelectedRef._grid = {search: jest.fn()} as any as IpxKendoGridComponent;
            c.ngOnInit();
            c.view$.subscribe();
        });
        it('should call the service to post the time', fakeAsync(() => {
            postTimeService.postResult$ = of({ rowsPosted: 0 });
            postTimeService.postTime = jest.fn().mockReturnValue(of({}));
            c.selectedEntityKey = 2;
            c.staffNameId = 0;
            c.postTime();
            expect(postTimeService.postTime).toHaveBeenCalledWith(c.selectedEntityKey, null, 0);
            tick(100);
            expect(c._postSelectedRef._grid.search).not.toHaveBeenCalled();
        }));
        it('should call the service to post all', fakeAsync(() => {
            c._postSelectedRef.getSelectedDates = jest.fn().mockReturnValue([new Date()]);
            postTimeService.postTime = jest.fn().mockReturnValue(of({ rowsPosted: 5, rowsIncomplete: 2, hasOfficeEntityError: false }));
            postTimeService.postResult$ = of({ rowsPosted: 5});
            c.selectedEntityKey = 2;
            c.staffNameId = 555;
            c.postTime();
            expect(postTimeService.postTime).toHaveBeenCalledWith(c.selectedEntityKey, null, 555);
            tick(100);
            expect(c._postSelectedRef._grid.search).toHaveBeenCalledTimes(1);
        }));
        it('should call the service to post selected items', (done) => {
            postTimeService.postResult$ = of({ rowsPosted: 0 });
            c.selectedPostType = '1';
            const datesToPost = [new Date(), new Date(2010, 10, 10)];
            c._postSelectedRef.getSelectedDates = jest.fn().mockReturnValue(datesToPost);
            c.selectedEntityKey = 2;

            c.postInitiated.subscribe((r) => {
                expect(r).toBeTruthy();
                done();
            });

            c.postTime();
            expect(postTimeService.postTime).toHaveBeenCalledWith(c.selectedEntityKey, datesToPost, null);
        });
        it('should call the service to post the entry', () => {
            postTimeService.postResult$ = of({ rowsPosted: 0 });
            postTimeService.postSelectedEntry = jest.fn().mockReturnValue(of({}));
            c.selectedEntityKey = 2;
            c.postEntryDetails = { entryNo: 1 };
            c.postTime();
            expect(postTimeService.postSelectedEntry).toHaveBeenCalledWith({ entryNo: 1 });
        });
        it('should close the post time modal if posting selected entry', fakeAsync(() => {
            postTimeService.postResult$ = of({ rowsPosted: 1 });
            c.postEntryDetails = { entryNo: 2 };
            c.postTime();
            expect(postTimeService.postSelectedEntry).toHaveBeenCalledWith(c.postEntryDetails);
            postTimeService.postTime();
            expect(modalRef.hide).toHaveBeenCalled();
            tick(100);
            expect(c._postSelectedRef._grid.search).toHaveBeenCalledTimes(1);
        }));
        it('does not display error when there are no case office entity errors', fakeAsync(() => {
            postTimeService.postResult$ = of({ rowsPosted: 10 });
            postTimeService.postTime = jest.fn().mockReturnValue(of({ rowsPosted: 10, rowsIncomplete: 1, hasOfficeEntityError: false }));
            c.postTime();
            expect(postTimeService.postTime).toHaveBeenCalledWith(c.selectedEntityKey, null, null);
            tick(100);
            expect(c._postSelectedRef._grid.search).toHaveBeenCalledTimes(1);
        }));
        it('should close the modal if posting in background', fakeAsync(() => {
            postTimeService.postResult$ = of({ isBackground: true });
            c.postTime();
            tick(100);
            expect(c._postSelectedRef._grid.search).not.toHaveBeenCalled();
            expect(modalRef.hide).toHaveBeenCalledTimes(1);
        }));
        it('should call the service to post for all staff', fakeAsync(() => {
            const datesToPost = [new Date(2020, 1, 1), new Date(2019, 1, 1), new Date(2018, 1, 1), new Date(2017, 1, 1)];
            c._postSelectedRef.getSelectedDates = jest.fn().mockReturnValue(datesToPost);
            postTimeService.postForAllStaff = jest.fn().mockReturnValue(of({ Resul: 'success', IsBackground: true }));
            postTimeService.postResult$ = of({ rowsPosted: 5});
            c.postAllStaff = true;
            c.selectedEntityKey = 2;
            c.staffNameId = 555;
            c.selectedPostType = '1';
            c.postAllStaffFromDate = new Date(1800, 1, 1);
            c.postAllStaffToDate = new Date(2021, 1, 1);
            c.postTime();
            expect(postTimeService.postForAllStaff).toHaveBeenCalledWith(c.selectedEntityKey, datesToPost, c.postAllStaffFromDate, c.postAllStaffToDate);
            tick(100);
            expect(c._postSelectedRef._grid.search).toHaveBeenCalledTimes(1);
        }));
    });
    describe('Change entity', () => {
        it('should set the selected entity', () => {
            c.onEntityChange(2);
            expect(c.selectedEntityKey).toBe(2);
        });
        it('should set the selected entity to the post entry details', () => {
            c.postEntryDetails = { entityKey: 999 };
            c.onEntityChange(100);
            expect(c.selectedEntityKey).toBe(100);
            expect(c.postEntryDetails.entityKey).toBe(100);
        });
    });

    describe('Cancel dialog', () => {
        it('should close the modal', () => {
            c.cancel();
            expect(modalRef.hide).toHaveBeenCalled();
        });
    });
});