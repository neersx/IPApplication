import { fakeAsync, tick } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { DateFunctions } from 'shared/utilities/date-functions';
import { TimeGap } from '../time-recording-model';
import { TimeCalculationServiceMock } from '../time-recording.mock';
import { TimeGapsService, WorkingHours } from './time-gaps.service';

describe('Service: TimeGaps', () => {
  let http: HttpClientMock;
  let timeCalcService: TimeCalculationServiceMock;
  let service: TimeGapsService;

  const selectedDate = new Date(2019, 11, 2, 0, 0, 0, 0);
  const timeRange = new WorkingHours(selectedDate, { fromSeconds: 8 * 3600, toSeconds: 18 * 3600 });

  const dateWith = (hours: number, minutes = 0, seconds = 0) => {
    const newDate = new Date(selectedDate);
    newDate.setHours(hours);
    newDate.setMinutes(minutes);
    newDate.setSeconds(seconds);

    return newDate;
  };

  beforeEach(() => {
    http = new HttpClientMock();
    timeCalcService = new TimeCalculationServiceMock();

    service = new TimeGapsService(http as any, timeCalcService as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('getting the time gaps', () => {
    it('should call the server to get data', () => {
      const someDate = new Date();
      timeCalcService.toLocalDate = jest.fn().mockReturnValue(someDate);
      http.get.mockReturnValue(of([]));

      service.getGaps(100, selectedDate, timeRange);

      expect(timeCalcService.toLocalDate).toHaveBeenCalledWith(selectedDate, true);
      expect(http.get.mock.calls[0][0]).toEqual('api/accounting/time/gaps');

      const params = JSON.parse(http.get.mock.calls[0][1].params.updates[0].value);
      expect(params.staffNameId).toEqual(100);
      expect(new Date(params.selectedDate)).toEqual(someDate);
    });

    it('should not call the server to get data, if calling again for same date and user', () => {
      const someDate = new Date();
      timeCalcService.toLocalDate = jest.fn().mockReturnValue(someDate);
      http.get.mockReturnValue(of([]));

      service.getGaps(100, selectedDate, null);
      service.getGaps(100, selectedDate, timeRange);
      service.getGaps(100, selectedDate, new WorkingHours(selectedDate, { fromSeconds: 100, toSeconds: 10 }));
      expect(http.get).toHaveBeenCalledTimes(2);
      expect(http.get.mock.calls[0][0]).toEqual('api/accounting/time/gaps');
      expect(http.get.mock.calls[1][0]).toEqual('api/accounting/time/settings/working-hours');
    });
    it('should adjust start time of the gap, if it falls outside selected range', () => {
      http.get.mockReturnValue(of([new TimeGap({
        startTime: dateWith(7),
        finishTime: dateWith(12)
      })]));

      service.getGaps(100, selectedDate, timeRange).subscribe(result => {
        expect(result[0].startTime).toEqual(dateWith(8));
        expect(result[0].finishTime).toEqual(dateWith(12));
        expect(result[0].durationInSeconds).toEqual(4 * 60 * 60);
      });
    });

    it('should adjust start time and finish time of the gap, if it falls outside selected range', () => {
      http.get.mockReturnValue(of([new TimeGap({
        startTime: dateWith(4),
        finishTime: dateWith(23)
      })]));

      service.getGaps(100, selectedDate, timeRange).subscribe(result => {
        expect(result[0].startTime).toEqual(dateWith(8));
        expect(result[0].finishTime).toEqual(dateWith(12));
        expect(result[0].durationInSeconds).toEqual(4 * 60 * 60);
      });
    });

    it('should add the gap with adjusted start time only if duration is more than a minute', () => {
      http.get.mockReturnValue(of([new TimeGap({
        startTime: dateWith(7),
        finishTime: dateWith(8, 1)
      })]));

      service.getGaps(100, selectedDate, timeRange).subscribe(result => {
        expect(result.length).toEqual(0);
      });
    });

    it('should add gap as is if the gap falls in the selected time range', () => {
      http.get.mockReturnValue(of([new TimeGap({
        startTime: dateWith(9),
        finishTime: dateWith(10),
        durationInSeconds: 100
      })]));

      service.getGaps(100, selectedDate, timeRange).subscribe(result => {
        expect(result[0].startTime).toEqual(dateWith(9));
        expect(result[0].finishTime).toEqual(dateWith(10));
        expect(result[0].durationInSeconds).toEqual(100);
      });
    });

    it('should adjust the end time of the gap, it falls outside the selected range', () => {
      http.get.mockReturnValue(of([new TimeGap({
        startTime: dateWith(17),
        finishTime: dateWith(19)
      })]));

      service.getGaps(100, selectedDate, timeRange).subscribe(result => {
        expect(result[0].startTime).toEqual(dateWith(17));
        expect(result[0].finishTime).toEqual(dateWith(18));
        expect(result[0].durationInSeconds).toEqual(60 * 60);
      });
    });

    it('should add the gap with adjusted finish time, only if duration is more than a minute', () => {
      http.get.mockReturnValue(of([new TimeGap({
        startTime: dateWith(17, 59),
        finishTime: dateWith(20)
      })]));

      service.getGaps(100, selectedDate, timeRange).subscribe(result => {
        expect(result.length).toEqual(0);
      });
    });
  });

  describe('creating entries for time gaps', () => {
    let today: Date;
    let request: any;
    let toLocalDateSpy: any;
    beforeEach(() => {
      today = new Date();
      request = [{ id: '1', startTime: new Date(today.setHours(8)), finishTime: new Date(today.setHours(9)) }, { id: '2', startTime: new Date(today.setHours(10)), finishTime: new Date(today.setHours(11)) }];
      http.post = jest.fn().mockReturnValue(of({}));
      toLocalDateSpy = jest.spyOn(DateFunctions, 'toLocalDate').mockImplementation((d) => { return d; });
    });
    it('should convert the dates to local', () => {
      service.addEntries(request);
      expect(toLocalDateSpy).toHaveBeenCalledTimes(4);
    });

    it('should call the correct url', () => {
      service.addEntries(request);
      expect(http.post).toHaveBeenCalledWith('api/accounting/time/save-gaps', expect.objectContaining([request[0], request[1]]));
    });
  });

  describe('fetch and save working hours', () => {
    it('getWorkingHoursFromServer calls server and converts returned data', done => {
      http.get.mockReturnValue(of({ fromSeconds: 1 * 3600, toSeconds: 15 * 3600 }));

      service.getWorkingHoursFromServer(selectedDate)
        .subscribe(data => {
          expect(data.from).toEqual(dateWith(1));
          expect(data.to).toEqual(dateWith(15));
          done();
        });

      expect(http.get).toHaveBeenCalledWith('api/accounting/time/settings/working-hours');
    });

    it('getWorkingHoursFromServer calls server and considers full day if correct data not returned', done => {
      http.get.mockReturnValue(of({}));

      service.getWorkingHoursFromServer(selectedDate)
        .subscribe(data => {
          expect(data.from).toEqual(dateWith(0));
          expect(data.to).toEqual(dateWith(23, 59, 59));
          done();
        });

      expect(http.get).toHaveBeenCalledWith('api/accounting/time/settings/working-hours');
    });

    it('saveWorkingHours calls to saves the working hours preference', fakeAsync(() => {
      http.post.mockReturnValue(of({}));
      const input = new WorkingHours(selectedDate, { fromSeconds: 1 * 3600, toSeconds: 15 * 3600 });
      service.preferenceSaved$().subscribe((result) => {
        expect(result).toBeTruthy();
        expect(http.post).toHaveBeenCalled();
        expect(http.post.mock.calls[0][0]).toBe('api/accounting/time/settings/update/working-hours');
        expect(http.post.mock.calls[0][1]).toEqual(input.getServerReadyString());
      });

      service.saveWorkingHours(input);
      tick(5000);
    }));
  });
});