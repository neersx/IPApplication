import { NgForm } from '@angular/forms';
import { Topic, TopicViewData } from './ipx-topic.model';

export interface TopicContract {
    topic: Topic;
    viewData?: TopicViewData;
    formData?: any;
    form?: NgForm;
    getFilterCriteria?(savedFormData?): any;
    discard?(): void;
    loadFormData?(formData): void;
    updateFormData?(): void;
    reloadData?(): void;
}
