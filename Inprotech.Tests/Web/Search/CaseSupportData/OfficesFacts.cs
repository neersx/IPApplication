using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search.CaseSupportData;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.CaseSupportData
{
    public class OfficesFacts : FactBase
    {
        [Fact]
        public void ShouldForwardCorrectSqlParametersToCommandForOffice()
        {
            var f = new OfficesFixture();
            var user = new UserBuilder(Db) {IsExternalUser = true}.Build();
            f.WithUser(user)
             .WithCulture("a")
             .WithSqlResults<PropertyTypeListItem>();

            f.Subject.Get();

            f.DbContext
             .Received(1)
             .SqlQuery<OfficeListItem>(
                                       FixtureBase.ListCaseSupportCommand,
                                       user.Id,
                                       "a",
                                       "Office",
                                       null,
                                       1,
                                       user.IsExternalUser);
        }
    }

    public class OfficesFixture : FixtureBase, IFixture<IOffices>
    {
        public OfficesFixture()
        {
            UserAccessSecurity = Substitute.For<IUserAccessSecurity>();

            Subject = new Offices(
                                  DbContext,
                                  SecurityContext,
                                  PreferredCultureResolver);
        }

        public IUserAccessSecurity UserAccessSecurity { get; set; }
        public IOffices Subject { get; }
    }
}