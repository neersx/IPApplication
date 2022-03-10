using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Web.Search.CaseSupportData;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Security;
using Xunit;
namespace Inprotech.Tests.Web.Search
{
    public class SavedQueriesFacts : FixtureBase
    {
        ISavedQueries CreateSubject()
        {
            WithUser(new User(Fixture.String(), false));

            return new SavedQueries(DbContext, SecurityContext, PreferredCultureResolver);
        }

        [Fact]
        public void ShouldFilterQueryNameOrderedByStartsWith()
        {
            WithSqlResults(new SavedQueryItem
                           {
                               QueryKey = Fixture.Integer(),
                               QueryName = "123 elephant 456",
                               IsRunable = true
                           },
                           new SavedQueryItem
                           {
                               QueryKey = Fixture.Integer(),
                               QueryName = "ella's due date",
                               IsRunable = true
                           },
                           new SavedQueryItem
                           {
                               QueryKey = Fixture.Integer(),
                               QueryName = "Test Report",
                               IsRunable = true
                           });

            var subject = CreateSubject();

            var r = subject.Get("el", Fixture.Enum<QueryContext>(), QueryType.All);

            Assert.Equal(new[] {"ella's due date", "123 elephant 456"}, r.Select(_ => _.Name));
        }

        [Fact]
        public void ShouldNotReturnQueriesMarkedNotRunnable()
        {
            WithSqlResults(new SavedQueryItem
            {
                QueryKey = Fixture.Integer(),
                QueryName = Fixture.UniqueName(),
                IsRunable = false
            });

            var subject = CreateSubject();

            Assert.Empty(subject.Get(null, Fixture.Enum<QueryContext>(), QueryType.All));
        }

        [Fact]
        public void ShouldReturnOrderedByQueryName()
        {
            WithSqlResults(new SavedQueryItem
                           {
                               QueryKey = Fixture.Integer(),
                               QueryName = "C",
                               IsRunable = true
                           },
                           new SavedQueryItem
                           {
                               QueryKey = Fixture.Integer(),
                               QueryName = "A",
                               IsRunable = true
                           },
                           new SavedQueryItem
                           {
                               QueryKey = Fixture.Integer(),
                               QueryName = "B",
                               IsRunable = true
                           });

            var subject = CreateSubject();

            var r = subject.Get(null, Fixture.Enum<QueryContext>(), QueryType.All);

            Assert.Equal(new[] {"A", "B", "C"}, r.Select(_ => _.Name));
        }

        [Fact]
        public void ShouldReturnPrivateQueriesOnlyIfPrivateQueryRequested()
        {
            WithSqlResults(new SavedQueryItem
            {
                QueryKey = Fixture.Integer(),
                QueryName = "The Public One",
                IsPublic = true,
                IsRunable = true
            }, new SavedQueryItem
            {
                QueryKey = Fixture.Integer(),
                QueryName = "The Private One",
                IsPublic = false,
                IsRunable = true
            });

            var subject = CreateSubject();

            var r = subject.Get(null, Fixture.Enum<QueryContext>(), QueryType.Private).ToArray();

            Assert.Single(r);
            Assert.Equal("The Private One", r.Single().Name);
        }

        [Fact]
        public void ShouldReturnPublicQueriesOnlyIfPublicQueryRequested()
        {
            WithSqlResults(new SavedQueryItem
            {
                QueryKey = Fixture.Integer(),
                QueryName = "The Public One",
                IsPublic = true,
                IsRunable = true
            }, new SavedQueryItem
            {
                QueryKey = Fixture.Integer(),
                QueryName = "The Private One",
                IsPublic = false,
                IsRunable = true
            });

            var subject = CreateSubject();

            var r = subject.Get(null, Fixture.Enum<QueryContext>(), QueryType.Public).ToArray();

            Assert.Single(r);
            Assert.Equal("The Public One", r.Single().Name);
        }

        [Fact]
        public void ShouldReturnSavedQueries()
        {
            var result = new SavedQueryItem
            {
                QueryKey = Fixture.Integer(),
                QueryName = Fixture.UniqueName(),
                Description = Fixture.String(),
                IsPublic = true,
                IsMaintainable = Fixture.Boolean(),
                IsRunable = true,
                IsReportOnly = Fixture.Boolean(),
                GroupKey = Fixture.Integer(),
                GroupName = Fixture.String()
            };

            WithSqlResults(result);

            var subject = CreateSubject();

            var r = subject.Get(null, Fixture.Enum<QueryContext>(), QueryType.All)
                           .Single();

            Assert.Equal(result.QueryKey, r.Key);
            Assert.Equal(result.QueryName, r.Name);
            Assert.Equal(result.Description, r.Description);
            Assert.Equal(result.IsPublic, r.IsPublic);
            Assert.Equal(result.IsMaintainable, r.IsMaintainable);
            Assert.Equal(result.IsRunable, r.IsRunable);
            Assert.Equal(result.IsReportOnly, r.IsReportOnly);
            Assert.Equal(result.GroupKey, r.GroupKey);
            Assert.Equal(result.GroupName, r.GroupName);
        }

        [Fact]
        public void ShouldReturnSavedPresentationQueries()
        {
            var result = new SavedQueryItem
            {
                QueryKey = Fixture.Integer(),
                QueryName = Fixture.UniqueName(),
                Description = Fixture.String(),
                HasPresentation = true
            };

            WithSqlResults(result);

            var subject = CreateSubject();

            var r = subject.GetSavedPresentationQueries((int)Fixture.Enum<QueryContext>());
            var data = r.Single();
            Assert.Equal(1, r.Count());
            Assert.Equal(result.QueryKey, data.Key);
            Assert.Equal(result.QueryName, data.Name);

        }
    }
}