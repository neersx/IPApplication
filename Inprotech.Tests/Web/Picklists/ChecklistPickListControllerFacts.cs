using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ChecklistPickListControllerFacts
    {
        public class ChecklistPickListControllerFixture : IFixture<ChecklistPickListController>
        {
            public ChecklistPickListControllerFixture(InMemoryDbContext db)
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();

                ChecklistPicklistMaintenance = Substitute.For<IChecklistPicklistMaintenance>();

                Subject = new ChecklistPickListController(db, cultureResolver, ChecklistPicklistMaintenance);
            }

            public IChecklistPicklistMaintenance ChecklistPicklistMaintenance { get; set; }

            public ChecklistPickListController Subject { get; }
        }

        public class ChecklistsMethod : FactBase
        {
            [Fact]
            public void MarksExactMatchOnDescription()
            {
                var f = new ChecklistPickListControllerFixture(Db);

                var chk1 = new ChecklistBuilder {Id = 4, Description = "ABC"}.Build().In(Db);
                var chk2 = new ChecklistBuilder {Id = 2, Description = "ABCDEF"}.Build().In(Db);
                var chk3 = new ChecklistBuilder {Id = 1, Description = "ABCDGF"}.Build().In(Db);
                var chk4 = new ChecklistBuilder {Id = 3, Description = "CDEFGH"}.Build().In(Db);

                var r = f.Subject.CheckLists(null, "ABC");

                var j = r.Data.OfType<ChecklistMatcher>().ToArray();

                Assert.Equal(3, j.Length);
                Assert.Equal(chk1.Description, j[0].Value);
            }

            [Fact]
            public void ReturnsChecklistContainingSearchStringOrderedByCode()
            {
                var f = new ChecklistPickListControllerFixture(Db);

                var c1 = new ChecklistBuilder {Id = 2, Description = "ABCDEF"}.Build().In(Db);
                var c2 = new ChecklistBuilder {Id = 1, Description = "KLMNO"}.Build().In(Db);
                var c3 = new ChecklistBuilder {Id = 3, Description = "EFDG"}.Build().In(Db);
                var c4 = new ChecklistBuilder {Id = 4, Description = "ABGEF"}.Build().In(Db);
                new CountryBuilder().Build().In(Db);

                var r = f.Subject.CheckLists(null, "AB");

                var j = r.Data.OfType<ChecklistMatcher>().ToArray();

                Assert.Equal(2, j.Length);
                Assert.Equal(c1.Id, j[0].Code);
                Assert.Equal(c4.Id, j[1].Code);
            }

            [Fact]
            public void ReturnsChecklistSortedByDescription()
            {
                var f = new ChecklistPickListControllerFixture(Db);

                var c1 = new ChecklistBuilder {Id = 2, Description = "A"}.Build().In(Db);
                var c2 = new ChecklistBuilder {Id = 1, Description = "B"}.Build().In(Db);
                var c3 = new ChecklistBuilder {Id = 3, Description = "C"}.Build().In(Db);

                var r = f.Subject.CheckLists();

                var j = r.Data.OfType<ChecklistMatcher>().ToArray();

                Assert.Equal(c1.Id, j[0].Code);
                Assert.Equal(c1.Description, j[0].Value);
                Assert.Equal(c2.Id, j[1].Code);
                Assert.Equal(c2.Description, j[1].Value);
                Assert.Equal(c3.Id, j[2].Code);
                Assert.Equal(c3.Description, j[2].Value);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new ChecklistPickListControllerFixture(Db);

                new ChecklistBuilder {Id = 1, Description = "KLMNO", ChecklistTypeFlag = 1}.Build().In(Db);
                new ChecklistBuilder {Id = 4, Description = "ABGEF", ChecklistTypeFlag = 2}.Build().In(Db);
                var j = new ChecklistBuilder {Id = 3, Description = "EFDG", ChecklistTypeFlag = 0}.Build().In(Db);

                var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.CheckLists(qParams);
                var checklists = r.Data.OfType<ChecklistMatcher>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(checklists);
                Assert.Equal(j.Id, checklists.Single().Code);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new ChecklistPickListControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("CheckLists").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("ChecklistMatcher", picklistAttribute.Name);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new ChecklistPickListControllerFixture(Db);
                var s = f.Subject;
                var r = new object();
                f.ChecklistPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new ChecklistMatcher();

                Assert.Equal(r, s.Update(1, model));
                f.ChecklistPicklistMaintenance.Received(1).Save(model, Operation.Update);
            }
        }

        public class AddOrDuplicateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new ChecklistPickListControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.ChecklistPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new ChecklistMatcher();

                Assert.Equal(r, s.AddOrDuplicate(model));
                f.ChecklistPicklistMaintenance.Received(1).Save(model, Operation.Add);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new ChecklistPickListControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.ChecklistPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.ChecklistPicklistMaintenance.Received(1).Delete(1);
            }
        }
    }
}