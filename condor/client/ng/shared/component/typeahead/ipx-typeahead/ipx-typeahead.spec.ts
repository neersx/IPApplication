import { ChangeDetectorRefMock, ElementRefTypeahedMock, FormControlHelperService, NgControl, PicklistModalService, Renderer2Mock, TypeAheadConfigProvider, TypeAheadService } from 'mocks';
import { of } from 'rxjs/internal/observable/of';
import { IpxModalOptions } from '../ipx-picklist/ipx-picklist-modal-options';
import { IpxTypeaheadComponent } from '../ipx-typeahead/ipx-typeahead';
import { TagsErrorValidator } from './typeahead.config.provider';

describe('IpxTypeaheadComponent', () => {
    let component: IpxTypeaheadComponent;
    let typeAheadConfigMock: any;
    let cdr: ChangeDetectorRefMock;
    let formControlHelperServiceMock: any;
    const ngControl = new NgControl();
    const typeAheadServiceMock = new TypeAheadService();
    const picklistModalServiceMock = new PicklistModalService();
    const elementRef = new ElementRefTypeahedMock();
    typeAheadConfigMock = new TypeAheadConfigProvider();
    const keyEvent = {stopPropagation: jest.fn()};
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        typeAheadConfigMock = new TypeAheadConfigProvider();
        formControlHelperServiceMock = new FormControlHelperService();
        component = new IpxTypeaheadComponent(typeAheadServiceMock as any, elementRef as any, Renderer2Mock as any,
            picklistModalServiceMock as any, typeAheadConfigMock,
            formControlHelperServiceMock, cdr as any, ngControl as any);
        component.options = typeAheadConfigMock;

    });

    it('should initialize ipx typeahead', () => {
        expect(component).toBeTruthy();
        expect(component.checkErrors).toBeDefined();
    });

    it('result should be undefined', () => {
        expect(component.results).toBeNull();
    });

    it('should call getDisplayValue method when multiselect is false', () => {
        component.isMultiSelect = false;
        const value = [{ id: 1 }, { id: 2 }];
        const displayValueSpy = jest.spyOn(component, 'getDisplayValue');
        component.writeValue(value);
        expect(displayValueSpy).toHaveBeenCalledWith(value);
    });

    it('should call move method with appropriate direction with onTagsKeydown with multiselect true', () => {
        component.isMultiSelect = true;
        const event = {
            keyCode: 39
        };
        const moveSpy = jest.spyOn(component, 'move');
        component.onTagsKeydown(event);
        expect(moveSpy).toHaveBeenCalledWith(1, false);
    });

    it('should call move and remove record from itemArray', () => {
        component.itemArray = [{ key: '1', code: 'C1' }];
        component.itemArray[0].isTagSelected = true;
        component.move(1, true);
        expect(component.itemArray.length).toEqual(0);
    });

    it('should call move next when direction is up and item array size if greater than 1', () => {
        component.itemArray = [{ key: '1', code: 'C1' }, { key: '2', code: 'C2' }];
        const moveNextSpy = jest.spyOn(component, 'moveNext');
        component.move(1, true);
        expect(moveNextSpy).toHaveBeenCalledWith(true);
    });

    it('should move the selected tag to the next position with deleteCurrent true, when move next is called', () => {
        component.itemArray = [{ key: '1', code: 'C1' }, { key: '2', code: 'C2', isTagSelected: true }, { key: '3', code: 'C3' }];
        component.moveNext(true);
        expect(component.itemArray.length).toEqual(2);
        expect(component.itemArray[1].isTagSelected).toEqual(true);
    });

    it('should move the selected tag to the first position with deleteCurrent false, when move next is called', () => {
        component.itemArray = [{ key: '1', code: 'C1' }, { key: '2', code: 'C2', isTagSelected: true }, { key: '3', code: 'C3' }];
        component.moveNext(false);
        expect(component.itemArray.length).toEqual(3);
        expect(component.itemArray[1].isTagSelected).toEqual(false);
        expect(component.itemArray[2].isTagSelected).toEqual(true);
    });

    it('should move the selected tag to the first position with deleteCurrent true, when move previous is called', () => {
        component.itemArray = [{ key: '1', code: 'C1' }, { key: '2', code: 'C2', isTagSelected: true }];
        component.movePrevious(true);
        expect(component.itemArray.length).toEqual(1);
        expect(component.itemArray[0].isTagSelected).toEqual(true);
    });

    it('should move the selected tag to the second position with deleteCurrent false, when move previous is called', () => {
        component.itemArray = [{ key: '1', code: 'C1' }, { key: '2', code: 'C2', isTagSelected: false }, { key: '3', code: 'C3', isTagSelected: true }];
        component.movePrevious(false);
        expect(component.itemArray.length).toEqual(3);
        expect(component.itemArray[1].isTagSelected).toEqual(true);
        expect(component.itemArray[2].isTagSelected).toEqual(false);
    });

    it('should call onblur() method on Blur event', () => {
        spyOn(component, 'onblur').and.callThrough();
        spyOn(component, 'checkErrors').and.callThrough();
        const blur: any = {};
        component.onblur(blur);
        expect(component.onblur).toHaveBeenCalled();
        expect(component.checkErrors).not.toHaveBeenCalled();
    });

    it('should call picklistModalService\'s open modal ', () => {
        const pkOpenModal = jest.spyOn(picklistModalServiceMock, 'openModal');
        component.openModal();
        expect(pkOpenModal).toHaveBeenCalled();
    });

    it('hitting F2 should call picklistModalService\'s open modal ', () => {
        const compOpenModal = jest.spyOn(component, 'openModal');
        component.keydown({keyCode: 113, ...keyEvent});
        expect(compOpenModal).toHaveBeenCalled();
    });

    it('should override auto-bind property when set at typeahead control level', () => {
        const pkOpenModal = jest.spyOn(picklistModalServiceMock, 'openModal');
        component.options.autobind = true;
        component.openModal();
        expect(pkOpenModal).toHaveBeenCalledWith(expect.any(IpxModalOptions), expect.objectContaining({ autobind: true }));
    });

    it('should call extend query with extendquery params ', () => {
        component.options = {};
        component.state = 'loading';
        component.extendQuery = (params) => params;

        spyOn(component, 'extendQuery').and.callThrough();
        typeAheadServiceMock.getApiData.mockReturnValue(of([]));

        const params = {
            search: 'a',
            params: JSON.stringify({
                skip: 0
            })
        };

        component.doSearch('a');
        expect(component.extendQuery).toHaveBeenCalledWith(params);
    });
    it('should call getDisplayText when showDisplayValue is true', () => {
        component.options = {
            showDisplayField: true,
            codeField: 'code',
            textField: 'description'
        };
        const value = { code: 'a', description: 'abc' };
        const displayTextSpy = jest.spyOn(component, 'getDisplayText');
        component.writeValue(value);
        expect(displayTextSpy).toHaveBeenCalledWith(value);
        expect(component.displayText).toBe('(a) abc');
    });

    it('should set text and displayText when showDisplayValue is true and description is null', () => {
        component.options = {
            showDisplayField: true,
            codeField: 'code',
            textField: 'description'
        };
        const value = { code: 'a', description: null };
        const displayTextSpy = jest.spyOn(component, 'getDisplayText');
        component.writeValue(value);
        expect(displayTextSpy).toHaveBeenCalledWith(value);
        expect(component.displayText).toBe('(a) ');
        expect(component.text).toBe('a');
    });

    it('should call getTagsError and return error ', () => {
        component.isMultiSelect = true;
        const errorObj: TagsErrorValidator = {
            validator: { duplicateElementImage: 'duplicate' },
            keys: [123, 234],
            keysType: 'key',
            applyOnChange: true
        };
        const errors = {
            error: 'duplicate',
            errorObj
        };

        component.itemArray = [{ key: 123, image: 'werwerwe' }, { key: 1423, image: 'werwerwe' }];
        component.getTagsError(errors.errorObj);
        const isError = component.itemArray.some(x => x.isError);
        expect(isError).toBe(true);

    });

    it('getTagErrors should not call if no error ', () => {
        component.isMultiSelect = true;
        component.control.control = jest.fn();
        jest.spyOn(component, 'getTagsError');
        component.itemArray = [{ key: 123, image: 'werwerwe' }, { key: 1423, image: 'werwerwe' }];
        component.getError();
        expect(component.getTagsError).not.toBeCalled();
    });

    it('should return custom not found error where specified ', () => {
        component.notFoundError = 'custom.notfound.error';
        component.control.control = { errors: { invalidentry: true } };
        component.showError = jest.fn().mockReturnValue(true);
        expect(component.getError()).toBe('field.errors.custom.notfound.error');
    });

    describe('focus', () => {
        it('onFocus calls to search, if required', () => {
            component.control.control.setErrors = jest.fn();
            component.control.control.updateValueAndValidity = jest.fn();
            typeAheadServiceMock.getApiData.mockReturnValue(of({}));
            const searchSpy = jest.spyOn(component, 'search');
            component.includeRecent = true;
            component.text = '';

            component.onfocus();
            expect(searchSpy).toHaveBeenCalled();
            searchSpy.mockClear();

            component.selectedItem = {};
            component.onfocus();
            expect(searchSpy).not.toHaveBeenCalled();
            searchSpy.mockClear();

            component.selectedItem = null;
            component.text = 'abcd';
            component.onfocus();
            component.onfocus();
            expect(searchSpy).toHaveBeenCalledTimes(1);
        });
    });
    describe('recent results', () => {
        beforeEach(() => {
            component.state = 'loading';
        });

        it('passes to include recent results if the flag is set', () => {
            typeAheadServiceMock.getApiData.mockReturnValue(of());
            component.includeRecent = true;
            typeAheadServiceMock.getApiData.mockClear();
            component.doSearch('abcd');
            expect(typeAheadServiceMock.getApiData).toBeCalled();
            expect(typeAheadServiceMock.getApiData.mock.calls[0][1].includeRecent).toBeTruthy();
        });
        it('sets the recent results correctly if server returns it', () => {
            component.isMultiSelect = true;
            const returnValue = {
                data: {
                    resultsContainsRecent: true,
                    recentResults: { data: [{}, {}] },
                    results: { data: [{}, {}, {}], pagination: { total: 10 } }
                }
            };
            const executeActionSpy = jest.spyOn(component, 'executeAction');
            typeAheadServiceMock.getApiData.mockReturnValue(of(returnValue));
            component.doSearch('abcd');

            expect(executeActionSpy).toHaveBeenCalled();
            expect(executeActionSpy.mock.calls[0][0].type).toEqual('search.response');
            expect(executeActionSpy.mock.calls[0][0].value.recentResults).toEqual(returnValue.data.recentResults.data);
            expect(executeActionSpy.mock.calls[0][0].value.data).toEqual(returnValue.data.results.data);
            expect(executeActionSpy.mock.calls[0][0].value.total).toEqual(10);
        });

        it('sets the results correctly if server returns only results without recent results', () => {
            const returnValue = {
                data: [{}, {}, {}],
                pagination: { total: 100 }
            };
            const executeActionSpy = jest.spyOn(component, 'executeAction');
            typeAheadServiceMock.getApiData.mockReturnValue(of(returnValue));
            component.doSearch('abcd');

            expect(executeActionSpy).toHaveBeenCalled();
            expect(executeActionSpy.mock.calls[0][0].type).toEqual('search.response');
            expect(executeActionSpy.mock.calls[0][0].value.recentResults).toBeNull();
            expect(executeActionSpy.mock.calls[0][0].value.data).toEqual(returnValue.data);
            expect(executeActionSpy.mock.calls[0][0].value.total).toEqual(100);
        });

        it('marks first item in recent results as selected', () => {
            const returnValue = {
                data: {
                    resultsContainsRecent: true,
                    recentResults: { data: [{}, {}] },
                    results: { data: [{}, {}, {}], pagination: { total: 10 } }
                }
            };
            const executeActionSpy = jest.spyOn(component, 'executeAction');
            typeAheadServiceMock.getApiData.mockReturnValue(of(returnValue));
            component.doSearch('abcd');

            expect(executeActionSpy.mock.calls[0][0].value.recentResults[0].$selected).toBeTruthy();
        });

        it('marks first item in results as selected', () => {
            const returnValue = {
                data: [{}, {}, {}],
                pagination: { total: 100 }
            };
            const executeActionSpy = jest.spyOn(component, 'executeAction');
            typeAheadServiceMock.getApiData.mockReturnValue(of(returnValue));
            component.doSearch('abcd');

            expect(executeActionSpy.mock.calls[0][0].value.data[0].$selected).toBeTruthy();
        });
    });
    describe('handleOnBlur', () => {
        it('sets state to invalid when no results found', () => {
            component.handleBlur([]);
            expect(component.state).toBe('invalid');
        });
        it('sets the state to idle and selects the top record', () => {
            spyOn(component, 'selectItem');
            component.handleBlur([{key: 1, value: 'first'}, {key: -1, value: 'second'}]);
            expect(component.state).toBe('idle');
            expect(component.selectItem).toHaveBeenCalledWith({ key: 1, value: 'first' });
        });
        it('does not automatically select if it includes Recent resultset and no text entered', () => {
            component.includeRecent = true;
            spyOn(component, 'selectItem');
            component.handleBlur([{ key: 1, value: 'first' }, { key: -1, value: 'second' }]);
            expect(component.state).toBe('idle');
            expect(component.selectItem).not.toHaveBeenCalledWith();
            expect(cdr.detectChanges).toHaveBeenCalled();
        });
        it('automatically selects if it includes Recent resultset and text entered', () => {
            component.includeRecent = true;
            component.text = 'f';
            spyOn(component, 'selectItem');
            component.handleBlur([{ key: 1, value: 'first' }, { key: -1, value: 'second' }]);
            expect(component.state).toBe('idle');
            expect(component.selectItem).toHaveBeenCalledWith({ key: 1, value: 'first' });
        });
    });
});