using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SavedSearchValidatorFacts
    {
        public class ValidateQueryExistsMethod : FactBase
        {
            void SetData(User user)
            {
                new Query {Id = 1, ContextId = (int) QueryContext.CaseSearch}.In(Db);
                new Query {Id = 2, ContextId = (int) QueryContext.CaseSearch, IdentityId = Fixture.Integer()}.In(Db);
                new Query {Id = 3, ContextId = (int) QueryContext.CaseSearch, IdentityId = user.Id}.In(Db);
                new Query {Id = 4, ContextId = (int) QueryContext.CaseSearchExternal, AccessAccountId = user.AccessAccount?.Id}.In(Db);
                new Query {Id = 5, ContextId = (int) QueryContext.CaseSearchExternal, IsPublicToExternal = true, AccessAccountId = new AccessAccountBuilder().Build().In(Db).Id}.In(Db);
                new Query {Id = 6, ContextId = (int) QueryContext.CaseSearch, IsClientServer = true}.In(Db);
            }

            [Theory]
            [InlineData(2, QueryContext.CaseSearch)]
            [InlineData(4, QueryContext.CaseSearch)]
            [InlineData(5, QueryContext.CaseSearchExternal)]
            [InlineData(6, QueryContext.CaseSearch)]
            public async Task ShouldThrowExceptionIfQueryNotFound(int queryId, QueryContext queryContext)
            {
                var f = new SavedSearchValidatorFixture(Db);
                SetData(f.User);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.ValidateQueryExists(queryContext, queryId));
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Theory]
            [InlineData(1, QueryContext.CaseSearch)]
            [InlineData(3, QueryContext.CaseSearch)]
            public async Task ShouldPassWhenQueryExistsForInternalUser(int queryId, QueryContext queryContext)
            {
                var f = new SavedSearchValidatorFixture(Db);
                SetData(f.User);
                Assert.True(await f.Subject.ValidateQueryExists(queryContext, queryId));
            }

            [Theory]
            [InlineData(4, QueryContext.CaseSearchExternal)]
            [InlineData(5, QueryContext.CaseSearchExternal)]
            public async Task ShouldPassWhenQueryExistsForExternalUser(int queryId, QueryContext queryContext)
            {
                var f = new SavedSearchValidatorFixture(Db);
                var user = UserBuilder.AsExternalUser(Db, null).Build().In(Db);
                f.SecurityContext.User.Returns(user);
                SetData(user);
                Assert.True(await f.Subject.ValidateQueryExists(queryContext, queryId));
            }

            [Fact]
            public async Task ShouldNotThrowExceptionIfItsClientServerSearchAndSavedSearchIsTrue()
            {
                var f = new SavedSearchValidatorFixture(Db);
                SetData(f.User);
                Assert.True(await f.Subject.ValidateQueryExists(QueryContext.CaseSearch, 6, true));
            }
        }

        public class SavedSearchValidatorFixture : IFixture<SavedSearchValidator>
        {
            public SavedSearchValidatorFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                User = new User("internal", false).In(db);
                SecurityContext.User.Returns(User);

                Subject = new SavedSearchValidator(db, SecurityContext);
            }

            public ISecurityContext SecurityContext { get; set; }
            public User User { get; }
            public SavedSearchValidator Subject { get; set; }
        }
    }
}