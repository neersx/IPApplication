import { of } from 'rxjs';
import { OfficeItems } from './offices.model';

export class OfficeServiceMock {
    private readonly testResponse = new OfficeItems();
    getOffices = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    getOffice = jest.fn().mockReturnValue(of(this.testResponse));
    getViewData = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    deleteOffices = jest.fn().mockReturnValue(of({ result: 'success' }));
    getPrinters = jest.fn();
    getRegions = jest.fn().mockReturnValue(of({}));
    saveOffice = jest.fn().mockReturnValue(of({ id: 1 }));
}