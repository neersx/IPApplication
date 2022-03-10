using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class RoleUsersProviderFacts : FactBase
    {
        [Fact]
        public async Task ReturnsUsersForEachRole()
        {
            var f = Subject();
            var admin = Fixture.String();
            var @internal = Fixture.String();
            var external = Fixture.String();
            NewRoles(admin);
            NewRoles(@internal, 3);
            NewRoles(external, 5);

            var r = (await f.Provide(Fixture.Today())).ToArray();

            Assert.Equal(3, r.Length);
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == WithSuffix(admin)).Value));
            Assert.Equal(3, ToInt(r.Single(_ => _.Name == WithSuffix(@internal)).Value));
            Assert.Equal(5, ToInt(r.Single(_ => _.Name == WithSuffix(external)).Value));
        }

        RoleUsersProvider Subject() => new RoleUsersProvider(Db);
        string WithSuffix(string text) => AnalyticsEventCategories.RolesNoOfUsersPrefix + text;
        int ToInt(string text) => Convert.ToInt32(text);

        void NewRoles(string roleName, int totalUsers = 1)
        {
            List<User> users = new List<User>();
            for (int i = 0; i < totalUsers; i++)
            {
                users.Add(new User().In(Db));
            }

            new Role()
            {
                RoleName = roleName,
                Users = users
            }.In(Db);
        }
    }
}