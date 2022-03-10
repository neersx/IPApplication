import { Injectable } from '@angular/core';

@Injectable()
export class KnownNameTypes {
  // tslint:disable-next-line:variable-name
  readonly Agent = 'A';
  // tslint:disable-next-line: variable-name
  readonly Debtor = 'D';
  // tslint:disable-next-line: variable-name
  readonly RenewalsDebtor = 'Z';
  // tslint:disable-next-line: variable-name
  readonly Owner = 'O';
  // tslint:disable-next-line: variable-name
  readonly Inventor = 'J';
  // tslint:disable-next-line: variable-name
  readonly StaffMember = 'EMP';
  // tslint:disable-next-line: variable-name
  readonly Instructor = 'I';
  // tslint:disable-next-line: variable-name
  readonly Signatory = 'SIG';
  // tslint:disable-next-line: variable-name
  readonly UnrestrictedNameTypes = '~~~';
  // tslint:disable-next-line: variable-name
  readonly Contact = '~CN';
  // tslint:disable-next-line: variable-name
  readonly Lead = '~LD';
  // tslint:disable-next-line: variable-name
  readonly CopiesTo = 'C';
  // tslint:disable-next-line: variable-name
  readonly InstructorsClient = 'H';
  // tslint:disable-next-line: variable-name
  readonly ChallengerOurSide = 'P';
}