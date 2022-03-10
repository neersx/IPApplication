import { HttpClientMock } from 'mocks';
import { BulkOperationType, RecordalStep, RecordalStepElement } from './affected-cases.model';
import { AffectedCasesService } from './affected-cases.service';
import { AddAffetcedRequestModel } from './model/affected-case.model';

describe('Service: affected cases', () => {
    let http: HttpClientMock;
    let service: AffectedCasesService;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new AffectedCasesService(http as any);
        service.stepElementForm = [
            { stepId: 1, rowId: 1, form: null, formData: null },
            { stepId: 1, rowId: 2, form: null, formData: null },
            { stepId: 2, rowId: 2, form: null, formData: null }
        ];
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    describe('getAffectedCases', () => {
        it('should call get for the affected cases API', () => {
            const params = { skip: 0, take: 10 };
            service.getAffectedCases(1, params);

            expect(http.get).toHaveBeenCalledWith(`api/case/${1}/affectedCases`, { params: { params: JSON.stringify(params), filter: JSON.stringify(null) } });
        });

        it('should call post for the affected cases columns', () => {
            service.getColumns$(1);

            expect(http.get).toHaveBeenCalledWith(`api/case/${1}/affectedCasesColumns`);
        });

        it('should call get for getRecordalSteps', () => {
            service.getRecordalSteps(1);
            expect(http.get).toHaveBeenCalledWith(`api/case/${1}/recordalSteps`);
        });

        it('should call get for the getRecordalStepElements', () => {
            service.getRecordalStepElements(1, 2, 3);
            expect(http.get).toHaveBeenCalledWith(`api/case/${1}/recordalStep/${2}/recordalType/${3}`);
        });

        it('should call post for the saveRecordalSteps', () => {
            const recordalSteps: RecordalStep = {
                caseId: 1, id: 1, stepId: 1, stepName: 'Step 1', recordalType: null, modifiedDate: '1999/01/01',
                caseRecordalStepElements: null
            };
            service.saveRecordalSteps(recordalSteps);
            expect(http.post).toHaveBeenCalledWith('api/case/recordalSteps/save', recordalSteps);
        });

        it('should clear the step element form data', () => {
            service.stepElementForm = [{ stepId: 1, rowId: 1, form: null, formData: null }];
            spyOn(service.elementFormDataChanged$, 'next');
            service.clearStepElementFormData();
            expect(service.stepElementForm).toEqual(null);
            expect(service.elementFormDataChanged$.next).toHaveBeenCalledWith(null);
        });

        it('should clear only the specific step element row form data if rowId is given', () => {

            spyOn(service.elementFormDataChanged$, 'next');
            service.clearStepElementRowFormData(1, 1);
            expect(service.stepElementForm.length).toEqual(2);
            expect(service.elementFormDataChanged$.next).toHaveBeenCalledWith([{ stepId: 1, rowId: 2, form: null, formData: null },
            { stepId: 2, rowId: 2, form: null, formData: null }]);
        });

        it('should clear all step elements related to the specific stepId', () => {
            spyOn(service.elementFormDataChanged$, 'next');
            service.clearStepElementRowFormData(1);
            expect(service.stepElementForm.length).toEqual(2);
        });

        it('should get the forData for the specific elementId', () => {
            const data = service.getStepElementRowFormData(1, 1);
            expect(data).toEqual({ stepId: 1, rowId: 1, form: null, formData: null });
        });

        it('should not return forData if not matching elementId', () => {
            const data = service.getStepElementRowFormData(3, 1);
            expect(data).toEqual(undefined);
        });

        it('should push the fresh form value when stepElememntForm is empty', () => {
            service.stepElementForm = null;
            service.setStepElementRowFormData(1, 1, null, null);
            expect(service.stepElementForm.length).toEqual(1);
            expect(service.stepElementForm).toEqual([{ stepId: 1, rowId: 1, form: null, formData: null }]);
        });

        it('should update the stepElememntForm for matching stepId and rowId', () => {
            const formData: any = { namePicklist: { key: 1, value: 'value1' }, addressPicklist: { key: 1, value: 'value1' } };
            service.setStepElementRowFormData(1, 1, null, formData);
            expect(service.stepElementForm.length).toEqual(3);
            expect(service.stepElementForm[0]).toEqual({ stepId: 1, rowId: 1, form: null, formData });
        });

        it('should push the new stepElememntForm for new stepId and rowId', () => {
            const formData: any = { namePicklist: { key: 1, value: 'value1' }, addressPicklist: { key: 1, value: 'value1' } };
            service.setStepElementRowFormData(2, 1, null, formData);
            expect(service.stepElementForm.length).toEqual(4);
            expect(service.stepElementForm[3]).toEqual({ stepId: 2, rowId: 1, form: null, formData });
        });

        it('should update the original recoralElements for the matching stepId and elementId', () => {
            service.stepElementForm = [
                { stepId: 1, rowId: 1, form: null, formData: { namePicklist: { key: 1, value: 'value1' }, addressPicklist: { key: 1, value: 'add1' } } },
                { stepId: 1, rowId: 2, form: null, formData: { namePicklist: { key: 2, value: 'value2' }, addressPicklist: { key: 2, value: 'add2' } } },
                { stepId: 2, rowId: 2, form: null, formData: { namePicklist: { key: 3, value: 'value3' }, addressPicklist: { key: 3, value: 'add3' } } }
            ];

            const recordalStepElements: Array<RecordalStepElement> = [
                { caseId: 1, id: 1, stepId: 1, elementId: 1, element: 'Element1', label: 'value', namePicklist: null, typeText: 'name' },
                { caseId: 1, id: 2, stepId: 2, elementId: 1, element: 'Element1', label: 'value', namePicklist: null, typeText: 'name' },
                { caseId: 1, id: 2, stepId: 2, elementId: 2, element: 'Element1', label: 'value', namePicklist: null, typeText: 'name' }
            ];
            service.originalStepElements = recordalStepElements;
            const data = service.updateOriginalRecordalElements();
            expect(data[0].namePicklist[0]).toEqual(service.stepElementForm[0].formData.namePicklist);
        });

        it('should call deleteAffectedCases with appropriate parameters', () => {
            const selectedRowKeys = ['123^11', '123^12'];
            const deSelectedRowKeys = ['123^22'];
            service.performBulkOperation(123, selectedRowKeys, deSelectedRowKeys, false, null, BulkOperationType.DeleteAffectedCases);
            expect(http.post).toHaveBeenCalledWith('api/case/123/DeleteAffectedCases', {
                isAllSelected: false, deSelectedRowKeys, selectedRowKeys, filter: null
            });
        });

        it('should call clear agents with appropriate parameters', () => {
            const selectedRowKeys = ['123^11', '123^12'];
            const deSelectedRowKeys = ['123^22'];
            service.performBulkOperation(123, selectedRowKeys, deSelectedRowKeys, false, null, BulkOperationType.ClearAffectedCaseAgent);
            expect(http.post).toHaveBeenCalledWith('api/case/123/ClearAffectedCaseAgent', {
                isAllSelected: false, deSelectedRowKeys, selectedRowKeys, filter: null
            });
        });

        it('should get existing cases on validation for country and officialNo', () => {
            service.validateAddAffectedCase('au', '1234');
            expect(http.post).toHaveBeenCalledWith('api/case/affectedCaseValidation', {
                country: 'au',
                officialNo: '1234'
            });
        });

        it('should call submitAffectedCases with correct parameters', () => {
            const request: AddAffetcedRequestModel = {
                caseId: 123,
                relatedCases: [],
                jurisdiction: 'AU',
                officialNo: '1243',
                recordalSteps: []
            };
            service.submitAffectedCase(request);
            expect(http.post).toHaveBeenCalledWith('api/case/recordalAffectedCase/save', request);
        });
    });
});
