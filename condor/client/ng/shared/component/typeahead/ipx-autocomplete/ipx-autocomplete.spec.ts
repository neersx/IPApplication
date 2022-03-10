// tslint:disable: no-floating-promise
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import * as _ from 'underscore';
import { DynamicItemTemplateComponent, IpxAutocompleteComponent } from '.';
import { TemplateType } from '../ipx-autocomplete/autocomplete/template.type';

describe('IpxAutocompleteComponent', () => {
    let component: IpxAutocompleteComponent;
    let fixture: ComponentFixture<IpxAutocompleteComponent>;

    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [HttpClientTestingModule],
            declarations: [IpxAutocompleteComponent, IpxAutocompleteComponent, DynamicItemTemplateComponent],
            providers: []
        });
        fixture = TestBed.createComponent(IpxAutocompleteComponent);
        component = fixture.componentInstance;
        component.options = {
            label: 'picklist.dataitem.Type',
            keyField: 'key',
            textField: 'code',
            codeField: 'code',
            apiUrl: 'api/picklists/dataItems',
            templateType: TemplateType.ItemCode
        };
        fixture.detectChanges();
    });

    it('should create autocomplete component', () => {
        expect(component).toBeTruthy();
    });

    it('Input fields should be initialized on ngOnInit', () => {
        expect(component.templateType).toEqual(TemplateType.ItemCode);
        expect(component.keyField).toEqual('key');
        expect(component.codeField).toEqual('code');
        expect(component.textField).toEqual('code');
    });

    it('evaluateAndCheckHasItems should combine and pick unique items for complete set', () => {
        component.keyField = 'id';
        component.recentResult = [{ id: 1 }, { id: 6 }, { id: 90 }];
        component.results = [{ id: 11 }, { id: 66 }, { id: 90 }];
        component.getResultSet();

        expect(component.completeResultSet.length).toEqual(5);

        expect(_.findIndex(component.completeResultSet, (n: any) => { return n.id === 1; })).toEqual(0);
        expect(_.findIndex(component.completeResultSet, (n: any) => { return n.id === 6; })).toEqual(1);
        expect(_.findIndex(component.completeResultSet, (n: any) => { return n.id === 90; })).toEqual(2);
        expect(_.findIndex(component.completeResultSet, (n: any) => { return n.id === 11; })).toEqual(3);
        expect(_.findIndex(component.completeResultSet, (n: any) => { return n.id === 66; })).toEqual(4);
    });

    it('evaluateAndCheckHasItems should take results as set if recents set is not available', () => {
        component.keyField = 'id';
        component.recentResult = null;
        component.results = [{ id: 11 }, { id: 66 }, { id: 90 }];
        component.getResultSet();

        expect(component.completeResultSet.length).toEqual(3);
    });
    it('isLastRecentResultsRecord checks if the record is last records from recent set', () => {
        component.keyField = 'id';
        component.recentResult = [{ id: 1 }, { id: 6 }, { id: 90 }];
        component.results = [{ id: 11 }, { id: 66 }, { id: 90 }];
        component.getResultSet();

        expect(component.completeResultSet[0].lastRecentResult).toBeFalsy();
        expect(component.completeResultSet[1].lastRecentResult).toBeFalsy();
        expect(component.completeResultSet[2].lastRecentResult).toBeTruthy();
        expect(component.completeResultSet[3].lastRecentResult).toBeFalsy();
        expect(component.completeResultSet[4].lastRecentResult).toBeFalsy();
    });

    it('displayCount checks condition to display total count', () => {
        component.recentResult = null;
        component.results = [{}, {}];
        component.total = 100;

        expect(component.displayCount()).toBeTruthy();

        component.recentResult = [{}];
        expect(component.displayCount()).toBeFalsy();

        component.recentResult = null;
        component.results = null;
        expect(component.displayCount()).toBeFalsy();

        component.results = [{}, {}];
        component.total = 1;
        expect(component.displayCount()).toBeFalsy();

        component.total = 2;
        expect(component.displayCount()).toBeFalsy();
    });
});
