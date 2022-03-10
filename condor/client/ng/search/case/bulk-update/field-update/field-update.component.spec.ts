import { ChangeDetectorRefMock } from 'mocks';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { FieldUpdateComponent } from './field-update.component';

describe('FieldUpdateComponent', () => {
    let component: FieldUpdateComponent;
    let cdRef: ChangeDetectorRefMock;
    beforeEach(() => {
        cdRef = new ChangeDetectorRefMock();
        component = new FieldUpdateComponent(cdRef as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('validate ngOnInit', () => {
        const caseIds = [11, 22];
        component.topic = new Topic();
        component.topic.params = new TopicParam();
        component.topic.params.viewData = {};
        component.topic.params.viewData.caseIds = caseIds;
        component.ngOnInit();
        expect(component.caseIds).toBe(caseIds);
    });

    it('validate clear', () => {
        component.formData.caseOffice = 'test';
        component.clear('caseOffice');
        expect(component.formData.caseOffice).toEqual('');
    });

    it('validate discard', () => {
        component.formData.purchaseOrder = 'test';
        component.discard();
        expect(component.formData.purchaseOrder).toEqual('');
    });

    it('validate getSaveData', () => {
        const caseOffice = { key: 11, value: '"Case office test' };
        const profitCentre = {
            code: 'MYC',
            description: 'MYC Partnership',
            entityName: 'Maxim Yarrow and Colman'
        };
        component.formData.caseOffice = caseOffice;
        component.formData.profitCentre = profitCentre;
        component.formData.purchaseOrder = 'test';
        component.formData.caseFamily = undefined;
        component.formControls = { caseFamily: true };
        const result = component.getSaveData();
        expect(result.caseOffice.key).toEqual(caseOffice.key);
        expect(result.profitCentre.key).toEqual(profitCentre.code);
        expect(result.purchaseOrder.key).toEqual('test');
        expect(result.purchaseOrder.value).toEqual('test');
        expect(result.caseFamily.toRemove).toBeTruthy();
    });

});