import { ChangeDetectorRefMock } from 'mocks';
import { of, throwError } from 'rxjs';
import { DmsIntegrationServiceMock } from '../dms-integration.service.mock';
import { DmsDataDownloadComponent } from './dms-data-download.component';

describe('Dms Datadownload', () => {

    let component: (viewData: any) => DmsDataDownloadComponent;
    let service: DmsIntegrationServiceMock;
    let cdr: ChangeDetectorRefMock;

    beforeEach(() => {
        service = new DmsIntegrationServiceMock();
        cdr = new ChangeDetectorRefMock();
        component = (viewData: any) => {
            const c = new DmsDataDownloadComponent(service as any, cdr as any);
            c.topic = {
                key: 'abc',
                title: 'abc'
            };
            (c.topic as any).viewData = viewData;
            c.form = {
                statusChanges: of({}),
                valueChanges: of({})
            } as any;
            c.ngOnInit();

            return c;
        };
    });

    describe('send all to dms', () => {
        let c;
        beforeEach(() => {
            c = component([]);
        });

        it('should invoke corresponding web api and update status', () => {
            const item = {
                dataSource: 'usptoPrivatePair',
                job: {
                    status: null
                }
            };
            c.sendAllToDms(item);

            expect(item.job.status).toBe('Started');
            expect(service.sendAllToDms$).toHaveBeenCalled();
        });

        it('should reset status if service returns errors', () => {
            const item = {
                dataSource: 'usptoPrivatePair',
                job: {
                    status: null
                }
            };
            service.sendAllToDms$ = jest.fn().mockReturnValue(throwError('error'));

            c.sendAllToDms(item);
            expect(service.sendAllToDms$).toHaveBeenCalledWith('usptoPrivatePair');
            expect(item.job.status).toBe(null);
        });
    });

    it('should acknowlege the error', () => {
        const c = component([]);
        const item = {
            dataSource: 'usptoPrivatePair',
            job: {
                jobExecutionId: 1,
                acknowledged: false
            }
        };

        c.acknowledge(item);
        expect(item.job.acknowledged).toBe(true);
        expect(service.acknowledge$).toHaveBeenCalledWith(1);
    });

    it('should find if loction had initial value', () => {
        const item = {
            dataSource: 'usptoPrivatePair',
            job: {
                jobExecutionId: 1,
                acknowledged: false
            },
            location: undefined
        };
        let c = component(item);
        expect(c.hasInitialLocation).toBeFalsy();

        item.location = 'abc';
        c = component(item);
        expect(c.hasInitialLocation).toBeTruthy();
    });

});