import { of } from 'rxjs';

export class FeatureDetectionMock {
    hasSpecificRelease$ = jest.fn().mockReturnValue(of(true));
    isIe = jest.fn();
    getAbsoluteUrl = jest.fn();
}