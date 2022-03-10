import { BehaviorSubjectMock } from 'mocks';
import { Observable } from 'rxjs';

export class RoleSearchMock {
    runSearch = jest.fn().mockReturnValue(new Observable());
    _previousStateParam$ = new BehaviorSubjectMock();
    _roleName$ = new BehaviorSubjectMock();
    overviewDetails = jest.fn().mockReturnValue(new Observable());
    rolesIds = [1, 2];
    deleteroles = jest.fn().mockReturnValue(new Observable());
    inUseRoles = [1, 2];
    updateRoleDetails = jest.fn().mockReturnValue(new Observable());
    saveRole = jest.fn().mockReturnValue(new Observable());
    protectedRoles = jest.fn().mockReturnValue([{ roleId: -20, roleName: 'user' }, { roleId: -21, roleName: 'internal' }, { roleId: -22, roleName: 'external' }]);
}