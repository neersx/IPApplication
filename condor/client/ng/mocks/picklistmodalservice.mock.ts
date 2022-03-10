import { of } from 'rxjs';

export class PicklistModalService {
    openModal = jest.fn();
    picklistSelected = of([]);
}