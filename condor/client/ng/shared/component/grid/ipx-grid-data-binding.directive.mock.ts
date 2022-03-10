import { IpxGridDataBindingDirective } from './ipx-grid-data-binding.directive';
jest.mock('./ipx-grid-data-binding.directive');

export class IpxGridDataBindingDirectiveMock {
    selectPage = jest.fn();
    addRow = jest.fn(() => 2);
    bindOneTimeData = jest.fn();
    clear = jest.fn();
    removeRow = jest.fn();
    editRow = jest.fn();
    closeRow = jest.fn();
}