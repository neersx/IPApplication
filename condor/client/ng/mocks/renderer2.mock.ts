export class Renderer2Mock {
    data: { [key: string]: any; };
    destroy = jest.fn();
    createElement = jest.fn();
    // createComment = jest.fn();
    // createText = jest.fn();
    appendChild = jest.fn();
    insertBefore = jest.fn();
    removeChild = jest.fn();
    selectRootElement = jest.fn();
    parentNode = jest.fn();
    nextSibling = jest.fn();
    setAttribute = jest.fn();
    removeAttribute = jest.fn();
    addClass = jest.fn();
    removeClass = jest.fn();
    setStyle = jest.fn();
    removeStyle = jest.fn();
    setProperty = jest.fn();
    setValue = jest.fn();
    listen = jest.fn();
}