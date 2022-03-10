import { HtmlPipe } from './html.pipe';

describe('HtmlPipe', () => {
  it('create an instance', () => {
    const pipe = new HtmlPipe();
    expect(pipe).toBeTruthy();
  });

  it('replaces simple carriage returns for line breaks', () => {
    const pipe = new HtmlPipe();
    const transformed = pipe.transform('test1\ntest2');
    expect(transformed).toBeTruthy();
    expect(transformed).toEqual('test1<br/>test2');
  });

  it('replaces complex carriage returns for single line breaks', () => {
    const pipe = new HtmlPipe();
    const transformed = pipe.transform('test1\n\rtest2');
    expect(transformed).toBeTruthy();
    expect(transformed).toEqual('test1<br/>test2');
  });

  it('replaces multiple carriage returns for multiple line breaks', () => {
    const pipe = new HtmlPipe();
    const transformed = pipe.transform('test1\n\ntest2');
    expect(transformed).toBeTruthy();
    expect(transformed).toEqual('test1<br/><br/>test2');
  });
});
