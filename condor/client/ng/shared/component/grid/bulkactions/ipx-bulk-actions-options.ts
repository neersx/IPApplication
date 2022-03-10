import { Observable } from 'rxjs';

export class IpxBulkActionOptions {
    id: string;
    icon: string;
    text: string;
    enabled: boolean | 'single-selection';
    click: (grid: any) => void;
    enabled$: Observable<boolean>;
    text$: Observable<string>;
    items: Array<any>;
}