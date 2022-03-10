import { Observable } from 'rxjs';
export class AdHocDateService {
    finalise = jest.fn().mockReturnValue(new Observable());
    bulkFinalise = jest.fn().mockReturnValue(new Observable());
    saveAdhocDate = jest.fn().mockReturnValue(new Observable());
    getPeriodTypes = jest.fn();
    nameDetails = jest.fn().mockReturnValue(new Observable());
    nameTypeRelationShip = jest.fn().mockReturnValue(new Observable());
    delete = jest.fn().mockReturnValue(new Observable());
    viewData = jest.fn().mockReturnValue(new Observable());
}