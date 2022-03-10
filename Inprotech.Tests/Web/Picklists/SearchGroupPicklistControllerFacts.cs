using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Queries;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class SearchGroupPicklistControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsSearchGroupsForGivenQueryContext()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);
                f.Setup(Db);

                var r = f.Subject.Search(null, null, 2);
                var queryGroups = r.Data.OfType<SearchGroupData>().ToArray();

                Assert.Equal(2, queryGroups.Length);
                Assert.Contains("1", queryGroups.Select(_ => _.Key));
                Assert.Contains("2", queryGroups.Select(_ => _.Key));
                Assert.DoesNotContain("3", queryGroups.Select(_ => _.Key));
                Assert.Equal("2", queryGroups[0].Key);
                Assert.Equal("Business", queryGroups[0].Value);
            }

            [Fact]
            public void ReturnsSearchGroupsContainingMatchingDescription()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);
                f.Setup(Db);

                var r = f.Subject.Search(null, "Ca", 2);
                var queryGroups = r.Data.OfType<SearchGroupData>().ToArray();

                Assert.Equal(1, queryGroups.Length);
                Assert.Equal("1", queryGroups[0].Key);
                Assert.Equal("Cases", queryGroups[0].Value);
            }

            [Fact]
            public void ThrowsExceptionIfQueryContextIsNotSpecified()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);

                Assert.Throws<ArgumentNullException>(() => { f.Subject.Search(); });
            }
        }

        public class SearchMenuGroup : FactBase
        {
            [Fact]
            public void GetSearchMenuById()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);
                f.Setup(Db);
                var p = f.Subject.SearchMenuGroup(1);
                Assert.Equal(2, p.ContextId);
                Assert.Equal("1", p.Key);
                Assert.Equal("Cases", p.Value);

            }

            [Fact]
            public void ThrowsExceptionWhenRecordNotForndInSearchMenu()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);
                f.Setup(Db);
                var p = f.Subject.SearchMenuGroup(1);
                var exception = Record.Exception(() => f.Subject.SearchMenuGroup( Fixture.Integer()));
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class MetadataMethod : FactBase
        {
            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new SearchGroupPicklistControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("Metadata")?.GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("SearchGroupData", picklistAttribute.Name);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.SearchGroupPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                List<QueryGroup> q = new List<QueryGroup>();
                q.Add(new QueryGroup { ContextId = 2, DisplaySequence = 1, GroupName = "Test Name", Id = 1 });
                Db.AddRange(q);
                var model = new QueryGroup();

                Assert.Equal(r, s.Update(1, model));
                f.SearchGroupPicklistMaintenance.Received(1).Save(model, Operation.Update);
            }
        }

        public class AddOrDuplicateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.SearchGroupPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                List<QueryGroup> q = new List<QueryGroup>();
                q.Add(new QueryGroup { ContextId = 2, DisplaySequence = 1, GroupName = "Test Name", Id = 1 });
                Db.AddRange(q);

                var model = new QueryGroup();

                Assert.Equal(r, s.AddOrDuplicate(model));
                f.SearchGroupPicklistMaintenance.Received(1).Save(model, Operation.Add);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new SearchGroupPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.SearchGroupPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.SearchGroupPicklistMaintenance.Received(1).Delete(1);
            }
        }

    }

    public class SearchGroupPicklistControllerFixture : IFixture<SearchGroupPicklistController>
    {
        public SearchGroupPicklistControllerFixture(InMemoryDbContext db)
        {

            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SearchGroupPicklistMaintenance = Substitute.For<ISearchGroupPicklistMaintenance>();

            Subject = new SearchGroupPicklistController(db, PreferredCultureResolver, SearchGroupPicklistMaintenance);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public SearchGroupPicklistController Subject { get; }

        public ISearchGroupPicklistMaintenance SearchGroupPicklistMaintenance { get; set; }

        public IEnumerable<QueryGroup> Setup(InMemoryDbContext db)
        {
            var queryGroup2 = new QueryGroup(1, "Cases", 2).In(db);
            var queryGroup1 = new QueryGroup(2, "Business", 2).In(db);
            var queryGroup3 = new QueryGroup(3, "Trademark", 3).In(db);

            return new[] { queryGroup1, queryGroup2, queryGroup3 };
        }
    }
}