import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class ImageService {

  constructor(private readonly http: HttpClient) { }

  getImage = (itemKey: number, type: 'case' | 'name', imageKey: number, maxWidth?: number, maxHeight?: number): Observable<any> => {

    return this.http
      .get(`api/search/${type}/image/` +
        encodeURI(imageKey.toString()) + '/' +
        encodeURI(itemKey.toString()) +
        (maxWidth != null
          ? '?maxWidth=' + encodeURI(maxWidth.toString())
          : '') +
        (maxHeight != null
          ? '&maxHeight=' + encodeURI(maxHeight.toString())
          : '')
      )
      .pipe(map((response: any) => {
        return response;
      }));
  };
}
