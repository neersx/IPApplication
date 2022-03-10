// export for convenience.
export { ActivatedRoute } from '@angular/router';
import { convertToParamMap, ParamMap, Params } from '@angular/router';
import { ReplaySubject } from 'rxjs';

export class ActivatedRouteStub {

  private readonly subject = new ReplaySubject<ParamMap>();

  constructor(initialParams?: Params) {
    this.setQueryParamMap(initialParams);
  }

  /** Set the paramMap observables's next value */
  setQueryParamMap(params?: Params): void {
    this.subject.next(convertToParamMap(params));
  }
}
