using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Configuration.Core;
using Inprotech.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Search.Roles;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Web.Search.Roles
{
    public class RolesValidatorFacts : FactBase
    {
        public class RolesValidatorFactsFixture : IFixture<RolesValidator>
        {
            public RolesValidatorFactsFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Subject = new RolesValidator(DbContext);
            }

            public IDbContext DbContext { get; }
            public RolesValidator Subject { get; }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ShouldReturnErrorIfRoleNameAlreadyExists()
            {
                var f = new RolesValidatorFactsFixture(Db);
                var role = new Role(1) { RoleName = "Role", Description = "Desc", IsExternal = true }.In(Db);

                var r = f.Subject.Validate(role.Id, role.RoleName, Operation.Add).ToArray();
                Assert.NotEmpty(r);
                Assert.Equal("rolename", r.First().Field);
                Assert.Equal("field.errors.notunique", r.First().Message);
            }

            [Fact]
            public void ShouldThrowExceptionIfRoleNameDoesNotExist()
            {
                var role = new Role(1) { RoleName = "Role", Description = "Desc", IsExternal = true }.In(Db);
                Assert.Throws<HttpResponseException>(() =>
                {
                    var f = new RolesValidatorFactsFixture(Db);
                    var _ = f.Subject.Validate(2, role.RoleName, Operation.Update).ToArray();
                });
            }
        }
    }
}
