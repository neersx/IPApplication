import { async } from '@angular/core/testing';
import { LocalSettings } from 'core/local-settings';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { GridNavigationServiceMock } from 'mocks';
import { of } from 'rxjs';
import * as _ from 'underscore';
import { RoleSearchService } from './role-search.service';
import { RoleSearch } from './roles.model';
describe('RoleSearchService', () => {
    let service: RoleSearchService;
    let httpClientSpy = { get: jest.fn(), post: jest.fn() };
    let localSettings: LocalSettings;
    const gridNavigationService = new GridNavigationServiceMock();
    beforeEach(() => {
        localSettings = new LocalSettingsMock();
        httpClientSpy = {
            get: jest.fn().mockReturnValue({
                pipe: (args: any) => {
                    return [];
                }
            }), post: jest.fn()
        };
        service = new RoleSearchService(httpClientSpy as any, gridNavigationService as any, localSettings);
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });
    it('should call runSearch', () => {
        httpClientSpy.get.mockReturnValue(of([]));
        spyOn(service, 'runSearch').and.returnValue(of([]));
        service.runSearch(null, null);
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    });

    it('should call the overviewDetails method', async(() => {
        httpClientSpy.get.mockReturnValue(of([]));
        service.overviewDetails(1);
        expect(httpClientSpy.get).toHaveBeenCalled();
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
    it('should call the taskDetails method', async(() => {
        httpClientSpy.get.mockReturnValue(of([]));
        service.taskDetails(1, null, null);
        expect(httpClientSpy.get).toHaveBeenCalled();
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
    it('should call the webPartDetails method', async(() => {
        httpClientSpy.get.mockReturnValue(of([]));
        service.webPartDetails(1, null);
        expect(httpClientSpy.get).toHaveBeenCalled();
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
    it('should call the subjectDetails method', async(() => {
        httpClientSpy.get.mockReturnValue(of([]));
        service.subjectDetails(1);
        expect(httpClientSpy.get).toHaveBeenCalled();
        spyOn(httpClientSpy, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should call the markInUseRoles method', () => {
        const data = [{ roleId: 1, persisted: true, inUse: false, selected: false },
        { roleId: 2, persisted: true, inUse: false, selected: false }];
        service.inUseRoles = [1];
        service.markInUseRoles(data);
        expect(data[0].persisted).toEqual(false);
        expect(data[0].inUse).toEqual(true);
        expect(data[0].selected).toEqual(true);
    });

    it('should call the deleteroles method', async(() => {
        httpClientSpy.post.mockReturnValue(of({ reslt: true }));
        service.deleteroles([1, 2, 3]);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should call the updateRoleDetails method', async(() => {
        httpClientSpy.post.mockReturnValue(of({ reslt: true }));
        service.updateRoleDetails({});
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should call the saveRole method', async(() => {
        httpClientSpy.post.mockReturnValue(of({ reslt: true }));
        service.saveRole(null, 'adding', 1);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should add new role', () => {
        const request = new RoleSearch();
        request.description = 'Role Description';
        request.roleName = 'Role1';
        request.isExternal = true;
        httpClientSpy.get.mockReturnValue(of([]));
        service.saveRole(request, 'adding', 1);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    });

    it('should update existing role', () => {
        const request = new RoleSearch();
        request.description = 'Role Description';
        request.roleName = 'Role1';
        request.isExternal = true;
        httpClientSpy.get.mockReturnValue(of([]));
        service.saveRole(request, 'updating', 1);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    });

    it('should duplicateRole role', () => {
        const request = new RoleSearch();
        request.description = 'Role Description';
        request.roleName = 'Role1';
        request.isExternal = true;
        httpClientSpy.get.mockReturnValue(of([]));
        service.saveRole(request, 'duplicateRole', 1);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    });
    it('should protectedRoles', async(() => {
        const result = service.protectedRoles();
        expect(result.length).toEqual(3);
        expect(result[0].roleId).toEqual(-20);
    }));
});