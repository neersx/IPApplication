using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ClassItemsPicklistControllerFacts : FactBase
    {
        public class SearchMethod : FactBase
        {
            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                f.PrepareData();
                var r = f.Subject.ClassItems("C1", "AU", "T");

                Assert.Equal(2, r.Data.Count());
            }

            [Fact]
            public void ReturnsPagedResultsWithParams()
            {
                var qParams = new CommonQueryParameters { SortBy = "ItemNo", SortDir = "asc", Skip = 1, Take = 1 };
                var f = new ClassItemsPicklistControllerFixture(Db);
                f.PrepareData();
                var r = f.Subject.ClassItems("C1", "AU", "T", qParams);
                var a = r.Data.OfType<Inprotech.Web.Picklists.ClassItem>().ToArray();

                Assert.Equal(2, r.Pagination.Total);
                Assert.Equal("I02", a[0].ItemNo);
            }

            [Fact]
            public void ReturnsItemsWithMatchedClassAndSubClass()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                f.PrepareData();
                var result = f.Subject.ClassItems("C2", "AU", "T", null, "02");

                var a = result.Data.OfType<Inprotech.Web.Picklists.ClassItem>().ToArray();

                Assert.Equal(2,result.Data.Count());
                Assert.Equal("I00", a[0].ItemNo);
            }

            [Fact]
            public void ReturnsPageResultsWithDefaultOrder()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                f.PrepareData();
                var result = f.Subject.ClassItems("C2", "AU", "T");

                var a = result.Data.OfType<Inprotech.Web.Picklists.ClassItem>().ToArray();

                Assert.Equal(4,result.Data.Count());
                Assert.Equal("I05", a[0].ItemNo);
                Assert.Null(a[0].SubClass);
                Assert.Equal("I03", a[1].ItemNo);
                Assert.Equal("01", a[1].SubClass);
                Assert.Equal("I00", a[2].ItemNo);
                Assert.Equal("02", a[2].SubClass);
                Assert.Equal("I04", a[3].ItemNo);
                Assert.Equal("02", a[3].SubClass);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void CallsGet()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new ClassItemSaveDetails();
                
                var id = Fixture.Integer();
                f.ClassItemPicklistMaintenance.Get(Arg.Any<int>()).ReturnsForAnyArgs(r);
                Assert.Equal(r, s.ClassItem(id));
                f.ClassItemPicklistMaintenance.ReceivedWithAnyArgs(1).Get(id);
            }
        }

        public class AddMethod : FactBase
        {
            [Fact]
            public void CallsAdd()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                var model = new ClassItemSaveDetails();
                f.ClassItemPicklistMaintenance.Save(Arg.Any<ClassItemSaveDetails>(), Arg.Any<Operation>()).ReturnsForAnyArgs(r);
                Assert.Equal(r, s.Add(new ClassItemSaveDetails()));
                f.ClassItemPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Add);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsUpdate()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                var model = new ClassItemSaveDetails();
                f.ClassItemPicklistMaintenance.Save(Arg.Any<ClassItemSaveDetails>(), Arg.Any<Operation>()).ReturnsForAnyArgs(r);
                Assert.Equal(r, s.Update(Fixture.Integer(), model));
                f.ClassItemPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Update);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                var id = Fixture.Integer();
                f.ClassItemPicklistMaintenance.Delete(Arg.Any<int>(), Arg.Any<bool>()).ReturnsForAnyArgs(r);
                Assert.Equal(r, s.Delete(id, false));
                f.ClassItemPicklistMaintenance.ReceivedWithAnyArgs(1).Delete(id, false);
            }
        }

        public class SubClassesMethod : FactBase
        {
            [Fact]
            public void ReturnsSubClassesNumericallySorted()
            {
                var f = new ClassItemsPicklistControllerFixture(Db);
                f.PrepareData();

                var r = f.Subject.SubClasses("AU", "T", "C2");
                var enumerable = r as dynamic[] ?? r.ToArray();

                Assert.Equal(2, enumerable.Length);
                Assert.Equal("01", enumerable.First());
                Assert.Equal("02", enumerable.Last());
            }
        }

        public class ClassItemsPicklistControllerFixture : IFixture<ClassItemPickListController>
        {
            public ClassItemsPicklistControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                ClassItemPicklistMaintenance = Substitute.For<IClassItemsPicklistMaintenance>();
                Subject = new ClassItemPickListController(DbContext, ClassItemPicklistMaintenance);
            }

            public InMemoryDbContext DbContext { get; }

            public ClassItemPickListController Subject { get; }

            public IClassItemsPicklistMaintenance ClassItemPicklistMaintenance { get; }

            public void PrepareData()
            {
                var languageCode = new TableTypeBuilder(DbContext) { Id = (short?)TableTypes.Language, Name = "Language" }.Build().In(DbContext);

                var class1 = new TmClass("AU", "C1", "T", 1) { Heading = "Heading 1" }.In(DbContext);
                var class2 = new TmClass("AU", "C2", "T", 1) { Heading = "Heading 2", SubClass = "01" }.In(DbContext);
                var class3 = new TmClass("AU", "C2", "T", 2) { Heading = "Heading 2", SubClass = "02" }.In(DbContext);
                var class4 = new TmClass("AU", "C2", "T", 3) { Heading = "Heading 2" }.In(DbContext);

                new InprotechKaizen.Model.Configuration.ClassItem("I01", "Description 1", languageCode.Id, class1.Id) { Class = class1 }.In(DbContext);
                new InprotechKaizen.Model.Configuration.ClassItem("I02", "Description 2", languageCode.Id, class1.Id) { Class = class1 }.In(DbContext);
                new InprotechKaizen.Model.Configuration.ClassItem("I03", "Description 3", languageCode.Id, class2.Id) { Class = class2 }.In(DbContext);
                new InprotechKaizen.Model.Configuration.ClassItem("I04", "Description 4", languageCode.Id, class3.Id) { Class = class3 }.In(DbContext);
                new InprotechKaizen.Model.Configuration.ClassItem("I00", "Description 4", languageCode.Id, class3.Id) { Class = class3 }.In(DbContext);
                new InprotechKaizen.Model.Configuration.ClassItem("I05", "Description 4", languageCode.Id, class4.Id) { Class = class4 }.In(DbContext);
                
            }
        }
    }
}
