import { EventEmitter } from '@angular/core';
import { Observable } from 'rxjs';

export class TranslatedServiceMock {
    language = '';
    languages = [];
    onLangChange: EventEmitter<any> = new EventEmitter();
    onTranslationChange: EventEmitter<any> = new EventEmitter();
    onDefaultLangChange: EventEmitter<any> = new EventEmitter();
    get(): Observable<string> {
        return new Observable<string>();
    }
    use(value: string): void {
        this.language = value;
    }
    addLangs(values: Array<string>): void {
        this.languages = values;
    }
    setDefaultLang(value: string): void {
        this.language = value;
    }
    getBrowserLang(): string {
        return this.language;
    }
    instant(value: string): string {
        return value;
    }
    setTranslation(value: string, values: any, concat: boolean): void {
        this.language = value;
    }
}
