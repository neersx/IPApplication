import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { FileLocationsItems } from './file-locations.model';
import { FileLocationsService } from './file-locations.service';

describe('Service: FileLocations', () => {
    let http: HttpClientMock;
    let service: FileLocationsService;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new FileLocationsService(http as any);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    describe('getFileLocations', () => {
        it('should call get for the file locations API', () => {
            const responseData = {
                data: {
                    data: [
                        {
                            caseKey: 123,
                            entryNo: 20,
                            chargeOutRate: null,
                            isIncomplete: false
                        }
                    ]
                }
            };
            const params = { skip: 0, take: 10 };
            service.http.get = jest.fn().mockReturnValue(of(responseData));
            service.getFileLocations(1, params, false).subscribe((res: any) => {
                expect(res[0].caseIrn).toBe(123);
            });
            expect(http.get).toHaveBeenCalledWith(`api/case/${1}/fileLocations/${false}`, { params: { params: JSON.stringify(params) } });
        });

        it('should call get for the getFileLocationForFilePart API', () => {
            const responseData = {
                data: {
                    data: [
                        {
                            caseKey: 123,
                            entryNo: 20,
                            chargeOutRate: null,
                            isIncomplete: false
                        }
                    ]
                }
            };
            const params = { skip: 0, take: 10 };
            service.http.get = jest.fn().mockReturnValue(of(responseData));
            service.getFileLocationForFilePart(1, params, 1).subscribe((res: any) => {
                expect(res[0].caseIrn).toBe(123);
            });
            expect(http.get).toHaveBeenCalledWith(`api/case/${1}/fileLocations`, { params: { params: JSON.stringify(params), filePartId: JSON.stringify(1) } });
        });

        it('should call get for the file locations history', () => {
            const column: GridColumnDefinition = { title: 'abc', field: 'filePartDescription' };
            service.getColumnFilterData$(column, 123, '');
            expect(http.get).toHaveBeenCalledWith(`api/case/${123}/fileLocations/filterData/${column.field}`, { params: { columnFilters: JSON.stringify('') } });
        });

        it('should call get validation errors', () => {
            const caseKey = 123;
            const currentRow: FileLocationsItems = {
                id: 1,
                fileLocationId: 123,
                fileLocation: 'abc',
                filePartId: 11,
                filePart: 'Part 1',
                barCode: 'barcode',
                whenMoved: new Date(),
                status: 'E',
                caseIrn: 'abc123'
            };

            const changedRows: any = [{
                id: 1,
                fileLocationId: 123,
                fileLocation: 'abc',
                filePartId: 11,
                filePart: 'Part 1',
                barCode: 'barcode',
                whenMoved: new Date(),
                status: 'E'
            },
            {
                id: 2,
                fileLocationId: 456,
                fileLocation: 'xyz',
                filePartId: 121,
                filePart: 'Part 2',
                barCode: 'barcode',
                whenMoved: new Date(),
                status: 'E'
            }];
            service.getValidationErrors(123, currentRow, changedRows);
            expect(http.post).toHaveBeenCalledWith('api/case/fileLocations/validate', {
                caseKey,
                currentRow,
                changedRows
            });
        });

        it('should call raisePendingChanges', () => {
            service.states.hasPendingChanges = false;
            service.raisePendingChanges(true);
            expect(service.states.hasPendingChanges).toBe(true);
        });

        it('should call raiseHasErrors', () => {
            service.states.hasErrors = false;
            service.raiseHasErrors(true);
            expect(service.states.hasErrors).toBe(true);
        });

        it('should format file location data', () => {
            const value = {
                id: 1,
                fileLocationId: 123,
                fileLocation: { key: 123, value: 'abc' },
                filePartId: 11,
                filePart: { key: 111, value: 'Part 1' },
                barCode: 'barcode',
                whenMoved: new Date(),
                issuedBy: { key: -123, displayName: 'Owner Name' },
                status: 'E',
                caseIrn: 'abc123',
                whenMovedTime: new Date()
            };

            const result = service.formatFileLocation(value);
            expect(result.fileLocation).toBe('abc');
            expect(result.filePart).toBe('Part 1');
            expect(result.issuedBy).toBe('Owner Name');
            expect(result.whenMoved).toBe(value.whenMoved);
        });
    });
});
