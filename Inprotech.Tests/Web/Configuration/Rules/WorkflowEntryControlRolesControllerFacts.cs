using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEntryControlRolesControllerFacts
    {
        public class GetUsersForRoleMethod : FactBase
        {
            [Fact]
            public void ReturnsUsernamesBelongingToRoleAlphabetically()
            {
                var role = new Role(Fixture.Integer()).In(Db);
                var user1 = new UserBuilder(Db) {UserName = Fixture.String("a")}.Build().In(Db);
                var user2 = new UserBuilder(Db) {UserName = Fixture.String("b")}.Build().In(Db);
                var user3 = new UserBuilder(Db) {UserName = Fixture.String("c")}.Build().In(Db);

                role.Users = new Collection<User> {user2, user3, user1};

                var subject = new WorkflowEntryControlRolesController(Db);

                var result = (subject.GetUsersForRole(role.Id) as IEnumerable<dynamic>)?.ToArray();
                
                Assert.Equal(user1.UserName, result.First().Username);
                Assert.Equal(FormattedName.For(user1.Name.LastName, user1.Name.FirstName), result.First().Name);

                Assert.Equal(user2.UserName, result.ElementAt(1).Username);
                Assert.Equal(FormattedName.For(user2.Name.LastName, user2.Name.FirstName), result.ElementAt(1).Name);

                Assert.Equal(user3.UserName, result.Last().Username);
                Assert.Equal(FormattedName.For(user3.Name.LastName, user3.Name.FirstName), result.Last().Name);
            }
        }
    }
}