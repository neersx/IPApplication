import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, CaseSearchServiceMock, ChangeDetectorRefMock, KnownNameTypesMock, TranslateServiceMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { NamesComponent } from '.';
import { NameFilteredPicklistScope } from './name-filtered-picklist-scope';
describe('NamesComponent', () => {
    let c: NamesComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        c = new NamesComponent(TranslateServiceMock as any, CaseSearchServiceMock as any,
            KnownNameTypesMock as any, StepsPersistanceSeviceMock as any, caseHelpermock as any, cdr as any);

        viewData = {
            isExternal: false,
            nameTypes: [{ key: 'a' }],
            numberTypes: []
        };
        c.nameTypes = [{ key: 'a' }];
        c.topic = {
            params: {
                viewData
            },
            key: 'Names',
            title: 'Names'
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));
    it('should clear name variants when not only one name is selected', () => {
        c.formData.names = ['variant1', 'variant2'];
        c.formData.namesOperator = '0';
        c.formData.nameVariant = { description: 'variant1' };
        c.nameChange();
        expect(c.nameVariants).toEqual(null);
        expect(c.formData.nameVariant).toEqual(null);
        expect(c.nameTypes).toEqual(viewData.nameTypes);
        expect(cdr.detectChanges).toHaveBeenCalled();
    });

    it('should clear name variants when operator is not matched', () => {
        c.nameVariants = ['variant1', 'variant2'];
        c.formData.namesOperator = '3';
        c.formData.nameVariant = { description: 'variant1' };
        c.nameChange();
        expect(c.nameVariants).toEqual(null);
        expect(c.formData.nameVariant).toEqual(null);
        expect(c.nameTypes).toEqual(viewData.nameTypes);
    });
    it('should clear name variants when operator is not matched', () => {
        c.nameVariants = ['variant1', 'variant2'];
        c.formData.namesOperator = '3';
        c.formData.nameVariant = { description: 'variant1' };
        c.nameChange();
        expect(c.nameVariants).toEqual(null);
        expect(c.formData.nameVariant).toEqual(null);
        expect(c.nameTypes).toEqual(viewData.nameTypes);
    });
    it('should disable input on isMyself Checked', () => {
        c.formData.staff = 'staff name';
        c.formData.signatory = 'signatory name';
        c.applyIsMyself('staff');
        expect(c.formData.staff).toBe(null);

        c.applyIsMyself('signatory');
        expect(c.formData.staff).toBe(null);

    });
    it('should generate correct case name filter', () => {
        c.formData.instructor = [{ key: 'I1' }, { key: 'I2' }];
        c.formData.instructorOperator = '1';
        c.formData.agentValue = [{ key: 'A1' }, { key: 'A2' }];
        c.formData.agent = 'A';
        c.formData.agentOperator = '2';

        const output = c.getFilterCriteria();
        expect(output.caseNameGroup).toEqual(
            jasmine.objectContaining({
                caseName: [
                    {
                        operator: '1',
                        typeKey: undefined,
                        nameKeys: { value: 'I1,I2' },
                        name: null,
                        nameVariantKeys: null
                    },
                    {
                        operator: '2',
                        typeKey: undefined,
                        nameKeys: { value: null },
                        name: [{ key: 'A1' }, { key: 'A2' }],
                        nameVariantKeys: null
                    }
                ]
            })
        );
    });
    it('should generate correct filter on othername', () => {
        c.formData.instructor = [{ key: 'I1' }, { key: 'I2' }];
        c.formData.instructorOperator = '1';
        c.formData.agentValue = 'A';
        c.formData.agentOperator = '2';

        c.formData.namesOperator = '1';
        c.formData.nameVariant = { key: '111001', description: 'variant1' };
        c.formData.names = { key: '1100' };

        let output = c.getFilterCriteria();

        expect(output).toEqual(
            jasmine.objectContaining({
                caseNameGroup: {
                    caseName: [
                        {
                            operator: '1',
                            typeKey: undefined,
                            nameKeys: { value: 'I1,I2' },
                            name: null,
                            nameVariantKeys: null
                        },
                        {
                            operator: '2',
                            typeKey: undefined,
                            nameKeys: { value: null },
                            name: 'A',
                            nameVariantKeys: null
                        },
                        {
                            operator: '1',
                            typeKey: undefined,
                            nameKeys: { value: '' },
                            name: null,
                            nameVariantKeys: '111001'
                        }
                    ]
                }
            })
        );
        c.formData.namesOperator = '5';
        c.formData.nameVariant = { key: '111001', description: 'variant1' };
        c.formData.names = null;
        output = c.getFilterCriteria();
        expect(output).toEqual(
            jasmine.objectContaining({
                caseNameGroup: {
                    caseName: [
                        {
                            operator: '1',
                            typeKey: undefined,
                            nameKeys: { value: 'I1,I2' },
                            name: null,
                            nameVariantKeys: null
                        },
                        {
                            operator: '2',
                            typeKey: undefined,
                            nameKeys: { value: null },
                            name: 'A',
                            nameVariantKeys: null
                        },
                        {
                            operator: '5',
                            typeKey: undefined,
                            nameKeys: { value: null },
                            name: null,
                            nameVariantKeys: '111001'
                        }
                    ]
                }
            })
        );

        c.formData.instructorOperator = '6';
        c.formData.instructorValue = 'abc';
        output = c.getFilterCriteria();
        expect(output).toEqual(
            jasmine.objectContaining({
                caseNameGroup: {
                    caseName: [
                        {
                            operator: '6',
                            typeKey: undefined,
                            nameKeys: { value: null },
                            name: null,
                            nameVariantKeys: null
                        },
                        {
                            operator: '2',
                            typeKey: undefined,
                            nameKeys: { value: null },
                            name: 'A',
                            nameVariantKeys: null
                        },
                        {
                            operator: '5',
                            typeKey: undefined,
                            nameKeys: { value: null },
                            name: null,
                            nameVariantKeys: '111001'
                        }
                    ]
                }
            })
        );
    });
    it('should generate correct name relationships filter', () => {
        const output = c.getFilterCriteria();
        expect(output.nameRelationships).toEqual({
            operator: '0',
            nameTypes: undefined,
            relationships: undefined
        });
    });
    it('should generate correct inherited name filter', () => {
        c.formData.inheritedNameType = 'iii';
        c.formData.inheritedNameTypeOperator = '0';
        c.formData.parentName = { key: 'ppp' };
        c.formData.parentNameOperator = '1';
        c.formData.defaultRelationship = 'ddd';
        c.formData.defaultRelationshipOperator = '2';
        const serviceOutPut = jest.spyOn(caseHelpermock, 'buildStringFilterFromTypeahead');
        const output = c.getFilterCriteria();
        expect(serviceOutPut).toHaveBeenCalledWith('iii', '0');
        expect(serviceOutPut).toHaveBeenCalledWith('ddd', '2');
        expect(output.inheritedName).toEqual({
            nameTypeKey: undefined,
            parentNameKey: undefined,
            defaultRelationshipKey: undefined
        });
    });
    it('should update the external scope of the name pick list', () => {
        c.namePickListExternalScope = new NameFilteredPicklistScope();
        c.formData = {};
        c.formData.namesType = 'A';
        c.nameTypes = [{ key: 'B', value: 'Bee' }, { key: 'A', value: 'Eh' }];

        c.namesTypeChanged();
        expect(c.namePickListExternalScope.filterNameType).toEqual('A');
        expect(c.namePickListExternalScope.nameTypeDescription).toEqual('Eh');

        c.formData.namesType = null;
        c.namesTypeChanged();
        expect(c.namePickListExternalScope.filterNameType).toBeNull();
        expect(c.namePickListExternalScope.nameTypeDescription).toBeNull();
    });

    it('client name types applicable to external user only', () => {
        const r = c.clientNameTypeShown('a');
        expect(r).toBe(true);
    });
    it('agent name type filter not shown to external user', () => {
        const r = c.clientNameTypeShown('A');
        expect(r).toBe(true);
    });
});
