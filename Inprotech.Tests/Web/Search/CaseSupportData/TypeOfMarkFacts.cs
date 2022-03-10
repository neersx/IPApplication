using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search.CaseSupportData;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.CaseSupportData
{
    public class TypeOfMarkFacts : FactBase
    {
        public TypeOfMarkFacts()
        {
            _fixture = new TypeOfMarkFixture();
            _fixture.WithUser(new UserBuilder(Db) {IsExternalUser = true}.Build())
                    .WithCulture("a")
                    .WithSqlResults<TypeOfMarkListItem>();
        }

        readonly TypeOfMarkFixture _fixture;

        [Fact]
        public void ShouldGetTypeOfMarkList()
        {
            _fixture.WithSqlResults(new TypeOfMarkListItem());

            var results = _fixture.Subject.Get();

            Assert.Single(results);
        }

        [Fact]
        public void ShouldInvokeGetTypeOfMarkListWithCorrectArguments()
        {
            _fixture.Subject.Get();

            _fixture.DbContext
                    .Received(1)
                    .SqlQuery<TypeOfMarkListItem>(
                                                  FixtureBase.ListCaseSupportCommand,
                                                  _fixture.SecurityContext.User.Id,
                                                  "a",
                                                  "TypeOfMark",
                                                  null,
                                                  1,
                                                  _fixture.SecurityContext.User.IsExternalUser);
        }
    }

    public class TypeOfMarkFixture : FixtureBase, IFixture<ITypeOfMark>
    {
        public ITypeOfMark Subject => new TypeOfMark(
                                                     DbContext,
                                                     SecurityContext,
                                                     PreferredCultureResolver);
    }
}