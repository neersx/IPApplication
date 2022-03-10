import { ModalServiceMock } from 'ajs-upgraded-providers/modal-service.mock';
import { ElementRefTypeahedMock } from 'mocks';
import { of } from 'rxjs';
import { IpxIeOnlyUrlComponent } from './ipx-ie-only-url.component';

describe('IpxIeOnlyUrlComponent', () => {
    let component: IpxIeOnlyUrlComponent;
    let featureDetectionMock: any;
    let modalServiceMock: ModalServiceMock;
    const element = new ElementRefTypeahedMock();
    beforeEach(() => {
        featureDetectionMock = {
            isIe: jest.fn(),
            getAbsoluteUrl: jest.fn(),
            hasSpecificRelease$: jest.fn()
        };
        modalServiceMock = new ModalServiceMock();
        component = new IpxIeOnlyUrlComponent(featureDetectionMock, modalServiceMock as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
    describe('ngOnInit', () => {
        it('should initialize isIe to true if feature detected', () => {
            featureDetectionMock.isIe.mockReturnValue(true);
            featureDetectionMock.hasSpecificRelease$.mockReturnValue(of(true));

            component.ngOnInit();

            expect(component.isIe).toBeTruthy();
            expect(component.inproVersion16).toBeTruthy();
        });

        it('should initialize isIe to false if feature not detected', () => {
            featureDetectionMock.isIe.mockReturnValue(false);
            featureDetectionMock.hasSpecificRelease$.mockReturnValue(of(false));
            component.ngOnInit();

            expect(component.isIe).toBeFalsy();
            expect(component.inproVersion16).toBeFalsy();
        });
    });
    describe('linkText  ', () => {
        it('should return the components text', () => {
            const testText = 'text text';
            component.text = testText;

            const componentText = component.linkText();

            expect(componentText).toEqual(testText);
        });
    });

    describe('showIeRequired   ', () => {
        it('should call modal service correctly', () => {
            featureDetectionMock.getAbsoluteUrl.mockReturnValue('test');
            component.showIeRequired();

            expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.objectContaining({ id: 'ieRequired', controllerAs: 'vm', url: 'test' }));
        });
    });
});
