import { EventEmitter } from '@angular/core';

export interface WizardStepComponent {
    title: string;
    cancel: EventEmitter<any>;
    onNavigateNext(): Promise<boolean>;
}
