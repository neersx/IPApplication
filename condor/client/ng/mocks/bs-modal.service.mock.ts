import { Observable, of } from 'rxjs';

export class BsModalServiceMock {
    show = jest.fn().mockReturnValue(new BsModalRefMock());
    hide = jest.fn();
    onHide = {
        subscribe: jest.fn().mockReturnValue(new Observable()),
        pipe: jest.fn().mockReturnValue(new Observable())
    };
    onShow = {
        subscribe: jest.fn().mockReturnValue(new Observable()),
        pipe: jest.fn().mockReturnValue(new Observable())
    };
    onHidden = {
        subscribe: jest.fn().mockReturnValue(new Observable())
    };
}

export class BsModalRefMock {
    hide = jest.fn();
    content = {
        okClicked: of(false),
        saveClicked: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        },
        deferClicked: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        },
        searchRecord: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        },
        searchColumnRecord: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        },
        onClose: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        },
        onClose$: of({}),
        confirmed$: {
            subscribe: jest.fn().mockReturnValue(new Observable()),
            pipe: jest.fn().mockReturnValue(new Observable())
        },
        cancelled$: {
            subscribe: jest.fn().mockReturnValue(new Observable()),
            pipe: jest.fn().mockReturnValue(new Observable())
        },
        finaliseClicked: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        },
        success$: {
            subscribe: jest.fn().mockReturnValue(new Observable()),
            pipe: jest.fn().mockReturnValue(new Observable())
        },
        sendClicked: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        },
        proceedClicked: {
            subscribe: jest.fn().mockReturnValue(new Observable())
        }
    };
    setClass = jest.fn();
}
