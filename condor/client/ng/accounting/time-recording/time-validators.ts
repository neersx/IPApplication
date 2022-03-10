import { AbstractControl, ValidationErrors } from '@angular/forms';

export class TimeRecordingValidators {
    static checkIfEndDateAfterStartDate(c: AbstractControl): ValidationErrors | null {
        if (!c) {
            return null;
        }
        if (!c.get('start').value || !c.get('finish').value) { return null; }
        // since its for sibling validations(cross validation viz., comparison b/w start & end in same form), it requires multiple conditions as its a common validation that's not control specific...
        // there's always a difference in milliseconds by the time the event triggers, so need to ignore ms
        const finishTime = new Date(c.get('finish').value);
        const startTime = new Date(c.get('start').value);
        const finishedSecs = finishTime.getTime() / 1000;
        const startSecs = startTime.getTime() / 1000;
        if (Math.trunc(finishedSecs) < Math.trunc(startSecs)) {
            c.get('finish').setErrors({ errorMessage: 'accounting.time.recording.validationMsgs.finishShouldBeLaterThanStart' });

            return { errorMessage: 'accounting.time.recording.validationMsgs.finishShouldBeLaterThanStart' };
        }
    }

    static enableSave(c: AbstractControl): ValidationErrors | null {
        if ((!!c.get('elapsedTime').value || !!c.get('activity').value) && (c.get('totalUnits').disabled || c.get('totalUnits').valid)) {
            return null;
        }

        return { errorMessage: ''};
    }
}