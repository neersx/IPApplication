import { TimeEntry } from '../time-recording-model';
import { TimeSearchServiceMock, UserInfoServiceMock } from '../time-recording.mock';
import { CopyTimeEntryComponent } from './copy-time-entry.component';

describe('CopyTimeEntryComponent', () => {
  let c: CopyTimeEntryComponent;
  let timeSearchService: TimeSearchServiceMock;
  let userInfoService: UserInfoServiceMock;

  beforeEach(() => {
    timeSearchService = new TimeSearchServiceMock();
    userInfoService = new UserInfoServiceMock();

    c = new CopyTimeEntryComponent(timeSearchService as any, userInfoService as any);
  });

  it('should create', () => {
    expect(c).toBeTruthy();
  });

  it('initializes the grid options', () => {
    c.ngOnInit();
    expect(c.searchGridOptions.columns.length).toEqual(6);
  });

  it('should call to get recent entries', () => {
    c.ngOnInit();
    c.searchGridOptions.read$({});
    expect(timeSearchService.recentEntries$).toHaveBeenCalled();
    expect(timeSearchService.recentEntries$.mock.calls[0][0]).toEqual(1);
    expect(timeSearchService.recentEntries$.mock.calls[0][1].take).toEqual(30);
  });

  it('emits selected entry on data item click', done => {
    const clickedEntry = new TimeEntry();

    c.ngOnInit();
    c.selectedEntry$.subscribe((entry) => {
      expect(entry).toEqual(clickedEntry);

      done();
    });

    c.dataItemClicked(clickedEntry);
  });

  it('emits selected entry as null on cancel', done => {
    c.ngOnInit();

    c.selectedEntry$.subscribe((entry) => {
      expect(entry).toBeNull();

      done();
    });

    c.cancel();
  });
});
