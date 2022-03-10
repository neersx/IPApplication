import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { SearchByCharacteristicComponent } from './search-by-characteristic.component';

describe('SearchByCharacteristicComponent', () => {
    let service: any;
  let component: SearchByCharacteristicComponent;
  beforeEach(() => {
      service = {};
    component = new SearchByCharacteristicComponent(new CaseValidCombinationService(), service);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
