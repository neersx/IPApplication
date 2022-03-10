import { NgForm } from '@angular/forms';

export interface ScreenDesignerSearchType {
    resetFormData(firstLoad?: boolean): void;
    form: NgForm;
    submitForm(): void;
}
