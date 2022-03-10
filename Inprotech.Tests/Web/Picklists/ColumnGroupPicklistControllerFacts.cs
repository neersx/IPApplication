using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Queries;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ColumnGroupPicklistControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsColumnGroupsContainingMatchingDescription()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);
                f.Setup(Db);

                var r = f.Subject.Search(null, "Group", (int)QueryContext.CaseSearchExternal);
                var columnGroupData = r.Data.OfType<QueryColumnGroupPayload>().ToArray();

                Assert.Equal(1, columnGroupData.Length);
                Assert.Equal((int)QueryContext.CaseSearchExternal, columnGroupData[0].ContextId);
                Assert.Equal(3, columnGroupData[0].Key);
                Assert.Contains("Group", columnGroupData[0].Value);
            }

            [Fact]
            public void ReturnsColumnGroupsForGivenQueryContext()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);
                f.Setup(Db);

                var r = f.Subject.Search(null, null, 2);
                var queryGroups = r.Data.OfType<QueryColumnGroupPayload>().ToArray();

                Assert.Equal(2, queryGroups.Length);
                Assert.Contains(1, queryGroups.Select(_ => _.Key));
                Assert.Contains(2, queryGroups.Select(_ => _.Key));
                Assert.DoesNotContain(3, queryGroups.Select(_ => _.Key));
                Assert.Contains("Group", queryGroups[0].Value);
            }

            [Fact]
            public void ReturnsColumnGroupById()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);
                f.Setup(Db);

                var r = f.Subject.ColumnGroup(1);
                Assert.Equal(2, r.ContextId);
                Assert.Contains("Group", r.Value);
            }

            [Fact]
            public void ReturnsExceptionColumnGroupByIdWhenRecodNotFound()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);
                f.Setup(Db);
                var exception = Record.Exception(() => f.Subject.ColumnGroup(Fixture.Integer()));
                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ThrowsExceptionIfQueryContextIsNotSpecified()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);

                Assert.Throws<ArgumentNullException>(() => { f.Subject.Search(); });
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.ColumnGroupPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var q = new List<QueryColumnGroup> { new QueryColumnGroup { ContextId = (int)QueryContext.CaseSearch, DisplaySequence = 1, GroupName = "Test Name", Id = 1 } };
                Db.AddRange(q);
                var model = new QueryColumnGroupPayload();

                Assert.Equal(r, s.Update(1, model));
                f.ColumnGroupPicklistMaintenance.Received(1).Save(model, Operation.Update);
            }
        }

        public class AddOrDuplicateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.ColumnGroupPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var q = new List<QueryColumnGroup> { new QueryColumnGroup { ContextId = (int)QueryContext.CaseSearch, DisplaySequence = 1, GroupName = "Test Name", Id = 1 } };
                Db.AddRange(q);

                var model = new QueryColumnGroupPayload();

                Assert.Equal(r, s.AddOrDuplicate(model));
                f.ColumnGroupPicklistMaintenance.Received(1).Save(model, Operation.Add);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new ColumnGroupPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.ColumnGroupPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.ColumnGroupPicklistMaintenance.Received(1).Delete(1);
            }
        }
    }

    public class ColumnGroupPicklistControllerFixture : IFixture<ColumnGroupPicklistController>
    {
        public ColumnGroupPicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            ColumnGroupPicklistMaintenance = Substitute.For<IColumnGroupPicklistMaintenance>();

            Subject = new ColumnGroupPicklistController(db, PreferredCultureResolver, ColumnGroupPicklistMaintenance);
        }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IColumnGroupPicklistMaintenance ColumnGroupPicklistMaintenance { get; set; }
        public ColumnGroupPicklistController Subject { get; }
        public IEnumerable<QueryColumnGroup> Setup(InMemoryDbContext db)
        {
            var queryColumnGroup1 = db.Set<QueryColumnGroup>().Add(new QueryColumnGroup
            {
                Id = 1,
                GroupName = Fixture.String("Group"),
                DisplaySequence = (short)Fixture.Integer(),
                ContextId = (int)QueryContext.CaseSearch
            });
            var queryColumnGroup2 = db.Set<QueryColumnGroup>().Add(new QueryColumnGroup
            {
                Id = 2,
                GroupName = Fixture.String("Group"),
                DisplaySequence = (short)Fixture.Integer(),
                ContextId = (int)QueryContext.CaseSearch
            });
            var queryColumnGroup3 = db.Set<QueryColumnGroup>().Add(new QueryColumnGroup
            {
                Id = 3,
                GroupName = Fixture.String("Group"),
                DisplaySequence = (short)Fixture.Integer(),
                ContextId = (int)QueryContext.CaseSearchExternal
            });
            return new[] { queryColumnGroup1, queryColumnGroup2, queryColumnGroup3 };
        }
    }
}