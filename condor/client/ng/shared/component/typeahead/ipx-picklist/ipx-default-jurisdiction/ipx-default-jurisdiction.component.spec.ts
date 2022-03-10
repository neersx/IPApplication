import { IpxDefaultJurisdictionComponent } from './ipx-default-jurisdiction.component';

describe('IpxDefaultJurisdictionComponent', () => {
    let component: IpxDefaultJurisdictionComponent;

    beforeEach(() => {
        component = new IpxDefaultJurisdictionComponent();
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate isDefaultJurisdiction with empty grid data', () => {
        const result = component.isDefaultJurisdiction();
        expect(result).toBeFalsy();
    });

    it('validate isDefaultJurisdiction with valid grid data', () => {
        component.resultGridData = [{ code: 'AB', isDefaultJurisdiction: false }, { code: 'XY', isDefaultJurisdiction: false }];
        const result = component.isDefaultJurisdiction();
        expect(result).toBeFalsy();
    });

    it('validate isDefaultJurisdiction with default Jurisdiction grid data', () => {
        component.resultGridData = [{ code: 'AB', isDefaultJurisdiction: true }, { code: 'XY', IsDefaultJurisdiction: true }];
        const result = component.isDefaultJurisdiction();
        expect(result).toBeTruthy();
    });

});