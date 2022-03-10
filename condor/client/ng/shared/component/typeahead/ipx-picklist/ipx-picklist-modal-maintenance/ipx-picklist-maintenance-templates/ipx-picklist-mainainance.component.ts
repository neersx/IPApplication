import { FormGroup } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';

export interface PicklistMainainanceComponent {
    entry: any;
    form: FormGroup;
    extendedActions?: any;
    isFormDirty?: BehaviorSubject<Boolean>;
}
