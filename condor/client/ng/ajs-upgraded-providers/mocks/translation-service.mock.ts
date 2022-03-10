export class TranslationServiceMock {
    use(): any {
        return 'en-AU';
    }
    instant = (translatedValue: any) => {
        return translatedValue;
    };
}
