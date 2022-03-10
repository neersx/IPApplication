// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration } from '@uirouter/angular';
import { FileLocationOfficeComponent } from './file-location-office.component';

export const fileLocationOffice: Ng2StateDeclaration = {
    name: 'filelocationoffice',
    url: '/configuration/file-location-office',
    component: FileLocationOfficeComponent,
    data: {
        pageTitle: 'fileLocationOffice.title'
    }
};