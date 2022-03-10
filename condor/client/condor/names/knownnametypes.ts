class KnownNameTypes {
  readonly Agent = 'A';
  readonly Debtor = 'D';
  readonly RenewalsDebtor = 'Z';
  readonly Owner = 'O';
  readonly Inventor = 'J';
  readonly StaffMember = 'EMP';
  readonly Instructor = 'I';
  readonly Signatory = 'SIG';
  readonly UnrestrictedNameTypes = '~~~';
  readonly Contact = '~CN';
  readonly Lead = '~LD';
  readonly CopiesTo = 'C';
  readonly InstructorsClient = 'H';
  readonly ChallengerOurSide = 'P';
}

angular.module('inprotech.names').service('KnownNameTypes', KnownNameTypes);
