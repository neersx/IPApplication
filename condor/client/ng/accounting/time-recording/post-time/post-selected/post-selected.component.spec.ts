import { UserInfoServiceMock } from 'accounting/time-recording/time-recording.mock';
import { ChangeDetectorRefMock, LocalSettingsMocks } from 'mocks';
import { of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { DateFunctions } from 'shared/utilities/date-functions';
import { PostSelectedComponent } from './post-selected.component';

describe('PostSelectedComponent', () => {
    let c: PostSelectedComponent;
    let postTimeService: any;
    let cdRef: any;
    let timeCalcService: any;
    let localSettings: any;
    let userInfo: any;

    beforeEach(() => {
        timeCalcService = { displaySeconds: jest.fn() };
        postTimeService = { postTime: jest.fn(), disablePostBtnSubj: of(true), getDates: jest.fn() };
        cdRef = new ChangeDetectorRefMock();
        localSettings = new LocalSettingsMocks();
        userInfo = new UserInfoServiceMock();
        c = new PostSelectedComponent(postTimeService, cdRef, timeCalcService, localSettings, userInfo);
        c._grid = new IpxKendoGridComponentMock() as any;
    });

    describe('OnInit', () => {
        it('initialises the grid options', () => {
            spyOn(c.recordsSelected, 'next');
            c.ngOnInit();
            expect(c.gridOptions).toBeDefined();
            expect(c.staffNameId).toBe(1);
            expect(c.gridOptions.pageable).toBeDefined();

            c.gridOptions.read$({skip: 0, take: 10});
            expect(postTimeService.getDates).toHaveBeenCalledWith(expect.objectContaining({ skip: 0, take: 10 }), 1, undefined, undefined, undefined);
            expect(c.gridOptions.columns[3].hidden).toBeTruthy();

            c.ngAfterViewInit();
            expect(c.recordsSelected.next).toHaveBeenCalledWith(false);
        });

        it('initialises the grid options for when can post for all', () => {
            spyOn(c.recordsSelected, 'next');
            c.postAllStaff = true;
            c.fromDate = DateFunctions.toLocalDate(new Date(2010, 10, 10));
            c.toDate = DateFunctions.toLocalDate(new Date(2010, 12, 12));
            c.ngOnInit();
            expect(c.gridOptions).toBeDefined();
            expect(c.staffNameId).toBe(1);
            expect(c.gridOptions.pageable).toBeDefined();

            c.gridOptions.read$({skip: 0, take: 10});
            expect(postTimeService.getDates).toHaveBeenCalledWith(expect.objectContaining({ skip: 0, take: 10 }), 1, c.fromDate, c.toDate, true);
            expect(c.gridOptions.columns[3].hidden).toBeFalsy();

            c.ngAfterViewInit();
            expect(c.recordsSelected.next).toHaveBeenCalledWith(false);
        });
    });

    describe('Post selected', () => {
        it('raise record selected event as true, if records are selected', done => {
            c.recordsSelected.subscribe((r: boolean) => {
                expect(r).toBeTruthy();
                done();
            });
            c._grid.getRowSelectionParams().allSelectedItems = ['non empty arr'];
            c.onRowSelectionChanged();
        });

        it('raise record selected event as false, if records are selected', done => {
            c.recordsSelected.subscribe((r: boolean) => {
                expect(r).toBeFalsy();
                done();
            });
            c.onRowSelectionChanged();
        });

        it('provides the selected dates in localDates format', () => {
            c._grid.getRowSelectionParams().allSelectedItems = [{ date: new Date(2010, 10, 10), staffNameId: 444 }, { date: new Date(2011, 10, 11), staffNameId: 567 }];
            const result = c.getSelectedDates();

            expect(result[0]).toEqual({date: DateFunctions.toLocalDate(new Date(2010, 10, 10)), staffNameId: 444});
            expect(result[1]).toEqual({date: DateFunctions.toLocalDate(new Date(2011, 10, 11)), staffNameId: 567});
        });
    });
});
