import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { KotFilterCriteria, KotFilterTypeEnum, KotTextType } from './kot-text-types.model';
import { KotTextTypesService } from './kot-text-types.service';

describe('KotTextTypeService', () => {

    let service: KotTextTypesService;
    let httpMock: HttpClientMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        httpMock.get.mockReturnValue(of({}));
        httpMock.put.mockReturnValue(of({}));
        service = new KotTextTypesService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('getKotTextTypes', () => {
        it('should call the api correctly ', () => {
            const criteria: KotFilterCriteria = {
                type: KotFilterTypeEnum.byCase
            };
            service.getKotTextTypes(criteria, null);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/kottexttypes/case', { params: { params: 'null', q: JSON.stringify(criteria) } });
        });
        it('should call the getKotPermissions api correctly ', () => {
            service.getKotPermissions();
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/kottexttypes/case/permissions/');
        });
    });
    describe('getKotTextTypeDetails', () => {

        it('should call the api correctly ', () => {
            service.getKotTextTypeDetails(1, KotFilterTypeEnum.byName);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/kottexttypes/name/1');
        });
    });
    describe('Saving Kot', () => {
        it('calls the correct API passing the parameters', () => {
            const entry: KotTextType = {
                textType: { key: 1, value: 'A', code: 'A' },
                hasCaseProgram: true,
                hasBillingProgram: false,
                hasNameProgram: false,
                hasTaskPlannerProgram: false,
                hasTimeProgram: false,
                isDead: false,
                isRegistered: true,
                isPending: true
            };
            service.saveKotTextType(entry, KotFilterTypeEnum.byCase);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/kottexttypes/case/save', entry);
        });
    });
    describe('Deleting Kot', () => {
        it('calls the correct API passing the parameters', () => {
            const entry1 = 1;
            service.deleteKotTextType(entry1, KotFilterTypeEnum.byCase);
            expect(httpMock.request).toHaveBeenCalled();
            expect(httpMock.request.mock.calls[0][0]).toBe('delete');
            expect(httpMock.request.mock.calls[0][1]).toBe('api/configuration/kottexttypes/case/delete/1');
        });
    });
});