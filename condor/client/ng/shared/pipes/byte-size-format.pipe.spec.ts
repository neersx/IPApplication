import { ByteSizeFormatPipe } from './byte-size-format.pipe';

describe('Byte size format pipe', () => {
    let pipe: ByteSizeFormatPipe;
    beforeEach(() => {
        pipe = new ByteSizeFormatPipe();
    });

    it('test values', () => {
        expect(pipe.transform(123)).toEqual('123.00 B');
        expect(pipe.transform(1024)).toEqual('1.00 KB');
        expect(pipe.transform(1234)).toEqual('1.21 KB');
        expect(pipe.transform(3538944)).toEqual('3.38 MB');
        expect(pipe.transform(3538944, 3)).toEqual('3.375 MB');
    });
});