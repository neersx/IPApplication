import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { FormGroup, NgForm, NgModelGroup } from '@angular/forms';

@Injectable()
export class CaseValidateCharacteristicsCombinationService {

constructor(private readonly http: HttpClient) { }

private readonly getKey = (searchCriteria: any, propertyName: string, key: string) => {
  return searchCriteria[propertyName] && searchCriteria[propertyName][key];
};

readonly build = (searchCriteria: any) => {
  if (searchCriteria == null) {
    return undefined;
  }

  return {
    caseType: this.getKey(searchCriteria, 'caseType', 'code'),
    caseCategory: this.getKey(searchCriteria, 'caseCategory', 'code'),
    caseProgram: this.getKey(searchCriteria, 'program', 'key'),
    jurisdiction: this.getKey(searchCriteria, 'jurisdiction', 'code'),
    propertyType: this.getKey(searchCriteria, 'propertyType', 'code'),
    subType: this.getKey(searchCriteria, 'subType', 'code'),
    basis: this.getKey(searchCriteria, 'basis', 'code'),
    office: this.getKey(searchCriteria, 'office', 'key'),
    profile: this.getKey(searchCriteria, 'profile', 'code'),
    checklist: this.getKey(searchCriteria, 'checklist', 'key'),
    includeProtectedCriteria: searchCriteria.protectedCriteria,
    includeCriteriaNotInUse: searchCriteria.criteriaNotInUse,
    matchType: searchCriteria.matchType
  };
};

  validateCaseCharacteristics$ = (form: FormGroup, purposeCode: string, setDirty = true): Promise<CaseValidCharacteristics> => {
  const c = this.build(form.value);

  return this.http.get<CaseValidCharacteristics>('api/configuration/rules/characteristics/validateCharacteristics', {
    params: {
      purposeCode,
      criteria: JSON.stringify(c)
    }
  }).toPromise().then(validationResult => {
    Object.keys(validationResult).forEach(key => {
      if (form.controls[key]) {
        if (!validationResult[key].isValid) {
          form.controls[key].setValue(null);
        } else if (validationResult[key].key) {
          form.controls[key].setValue(validationResult[key]);
        }
        if (setDirty) {
          form.controls[key].markAsDirty();
          form.controls[key].markAsTouched();
        }
      }
    });

    return validationResult;
  });
};
}

export class CaseValidCharacteristics {
  applyTo: string;
  basis: ValidCharacteristics;
  caseCategory: ValidCharacteristics;
  caseType: ValidCharacteristics;
  jurisdiction: ValidCharacteristics;
  office: ValidCharacteristics;
  program: ValidCharacteristics;
  propertyType: ValidCharacteristics;
  subType: ValidCharacteristics;
}

class ValidCharacteristics {
  isValid: boolean;
  key: string;
  value: string;
  code: string;
}
