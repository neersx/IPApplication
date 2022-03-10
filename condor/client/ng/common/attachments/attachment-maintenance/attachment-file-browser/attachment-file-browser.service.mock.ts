import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

export class AttachmentFileBrowserServiceMock {
  getDirectoryFolders: (path: string) => Observable<jest.Mock> = jest.fn();

  getDirectoryFiles: (path: string) => Observable<jest.Mock> = jest.fn();
}
