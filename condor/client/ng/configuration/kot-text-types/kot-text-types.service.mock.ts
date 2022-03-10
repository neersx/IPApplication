import { of } from 'rxjs';
import { KotTextTypesItems } from './kot-text-types.model';

export class KotTextTypesServiceMock {
    private readonly testResponse = new KotTextTypesItems();
    getKotTextTyepes = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    getKotTextTypeDetails = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    getKotPermissions = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    deleteKotTextType = jest.fn().mockReturnValue(of({ result: 'success' }));
}