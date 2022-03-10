import { of } from 'rxjs';
import { FileLocationOfficeItems } from './file-location-office.model';

export class FileLocationOfficeServiceMock {
    private readonly testResponse = new FileLocationOfficeItems();
    getFileLocationOffices = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    saveFileLocationOffice = jest.fn().mockReturnValue(of({}));
}