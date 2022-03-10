using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Roles
{
    public class RolesDbSetup
    {
        public dynamic SetupData()
        {
            dynamic data = null;
            DbSetup.Do(x =>
            {
                var permissions = x.DbContext.Set<Permission>();
                var role1 = new Role{RoleName = "e2e role external", Description = "e2e external description", IsExternal = true};
                var role2 = new Role {RoleName = "e2e role internal", Description = "e2e internal description", IsExternal = false};
                x.Insert(role1);
                x.Insert(role2);
                
                permissions.Add(new Permission("TASK", 26,  0)
                                 {
                                     LevelKey = role2.Id,
                                     LevelTable = "ROLE",
                                     ObjectIntegerKey = (int)ApplicationTask.MaintainCase
                                 });
                permissions.Add(new Permission("DATATOPIC", 1,  0)
                {
                    LevelKey = role2.Id,
                    LevelTable = "ROLE",
                    ObjectIntegerKey = 2
                });

                permissions.Add(new Permission("MODULE", 1,  0)
                {
                    LevelKey = role2.Id,
                    LevelTable = "ROLE",
                    ObjectIntegerKey = -8
                });

                x.DbContext.SaveChanges();

                data = new
                {
                    role1,
                    role2
                };
            });
            return data;
        }
    }
}
