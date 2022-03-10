import { async } from '@angular/core/testing';
import { jsonUtilities } from './json-utilities';

describe('jsonUtilities', () => {

    describe('splitKeyedJSONObject', () => {
        it('should return null for a null object', async(() => {
            const objectToBeParsed = null;

            const newObject = jsonUtilities.splitKeyedJSONObject(objectToBeParsed);

            return expect(newObject).toEqual(null);
        }));

        it('should parse and maintain existing hierarchical data as expected', async(() => {
            const objectToBeParsed = {
                parentOne: {
                    value: 1
                }
            };

            const newObject = jsonUtilities.splitKeyedJSONObject(objectToBeParsed);

            return expect(newObject).toEqual({
                parentOne: {
                    value: 1
                }
            });
        }));

        it('should parse an object with a . delimited string as a key as a hierarchical object, splitting out top level parents', async(() => {
            const objectToBeParsed = {
                'parentTwo.subParent1': {
                    value: 1
                },
                'parentThree.subParent1': {
                    value: 2
                }
            };

            const newObject = jsonUtilities.splitKeyedJSONObject(objectToBeParsed);

            return expect(newObject).toEqual({
                parentTwo: {
                    subParent1:
                    {
                        value: 1
                    }
                },
                parentThree: {
                    subParent1: {
                        value: 2
                    }
                }
            });
        }));

        it('should parse an object with a . delimited string as a key as a hierarchical object, splitting out sub parents into hierarchical object', async(() => {
            const objectToBeParsed = {
                'parentThree.subParent1': {
                    value: 2
                },
                'parentThree.subParent2.value': 3
            };

            const newObject = jsonUtilities.splitKeyedJSONObject(objectToBeParsed);

            return expect(newObject).toEqual({
                parentThree: {
                    subParent1: {
                        value: 2
                    },
                    subParent2: {
                        value: 3
                    }
                }
            });
        }));
    });
});
