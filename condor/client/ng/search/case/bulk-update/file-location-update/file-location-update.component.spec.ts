
import { NgForm } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { BackgroundNotificationServiceMock } from 'rightbarnav/background-notification/background-notification.service.mock';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { FileLocationUpdateComponent } from './file-location-update.component';

describe('FileLocationUpdateComponent', () => {
    let component: FileLocationUpdateComponent;
    const changeDetectorRefMock = new ChangeDetectorRefMock();
    const backgroundNotificationServiceMock = new BackgroundNotificationServiceMock();
    beforeEach(() => {
        component = new FileLocationUpdateComponent(changeDetectorRefMock as any, backgroundNotificationServiceMock as any);
        component.formData = {
            toRemove: true,
            fileLocation: null,
            movedBy: null,
            bayNumber: null,
            whenMoved: Date
        };
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        const caseIds = [11, 12];
        component.topic = new Topic();
        component.topic.params = new TopicParam();
        component.topic.params.viewData = { caseIds };
        component.ngOnInit();
        expect(component.caseIds).toEqual(caseIds);
        expect(_.isFunction((component.topic as any).getSaveData)).toBeTruthy();
        expect(_.isFunction((component.topic as any).discard)).toBeTruthy();
    });

    it('validate discard', () => {
        component.formData.fileLocation = { key: 12, value: 'test file' };
        component.formData.movedBy = { key: 33, value: 'test staff' };
        component.formData.bayNumber = 'Bay Number-01';
        component.discard();
        expect(component.formData.fileLocation).toBeNull();
        expect(component.formData.movedBy).toBeNull();
        expect(component.formData.bayNumber).toBeNull();
    });

    it('validate discard', () => {
        component.formData.fileLocation = { key: 12, value: 'test file' };
        component.formData.movedBy = { key: 33, value: 'test staff' };
        component.formData.bayNumber = 'Bay Number-01';
        component.discard();
        expect(component.formData.fileLocation).toBeNull();
        expect(component.formData.movedBy).toBeNull();
        expect(component.formData.bayNumber).toBeNull();
    });

    it('validate isValid', () => {
        component.form = new NgForm(null, null);
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('validate getSaveData for saving file location', () => {
        component.formData.fileLocation = { key: 12, value: 'test file' };
        component.formData.movedBy = { key: 33, value: 'test staff' };
        component.formData.bayNumber = 'Bay Number-01';
        component.clear = false;

        const result = component.getSaveData() as any;
        expect(result.fileLocation.fileLocation).toEqual(component.formData.fileLocation.key);
        expect(result.fileLocation.movedBy).toEqual(component.formData.movedBy.key);
        expect(result.fileLocation.bayNumber).toEqual(component.formData.bayNumber);
        expect(result.fileLocation.toRemove).toBeFalsy();
    });

    it('validate getSaveData for removing file location', () => {
        component.formData.fileLocation = { key: 120, value: 'new test file' };
        component.formData.movedBy = { key: 331, value: 'new test staff' };
        component.clear = true;

        const result = component.getSaveData() as any;
        expect(result.fileLocation.fileLocation).toEqual(component.formData.fileLocation.key);
        expect(result.fileLocation.movedBy).toEqual(component.formData.movedBy.key);
        expect(result.fileLocation.bayNumber).toBeNull();
        expect(result.fileLocation.toRemove).toBeTruthy();
    });

});