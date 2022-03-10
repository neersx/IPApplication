using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class ClassesControllerFacts : FactBase
    {
        public class ClassSummaryMethod : FactBase
        {
            [Fact]
            public void ShouldReturnCaseWithOneClassItemAndClass()
            {
                var f = new ClassesControllerFixture(Db);
                var setupData = f.SetupData(allowSubClass: 2m);

                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                    .WithClass("C1", "I1").WithAllowSubClass(setupData.propertyType)
                    .Build();
 
                new CaseClassItem(@case.Id, setupData.definedItemDefault01.Id).In(Db);

                var r = f.Subject.CaseClassesSummary(@case.Id);

                Assert.Equal(r.TotalItem, 1);
                Assert.Equal(r.TotalLocal, 1);
                Assert.Equal(r.TotalInternational, 1);
                Assert.Equal(r.LocalClasses, "C1");
                Assert.Equal(r.InternationalClasses, "I1");
            }

            [Fact]
            public void ShouldReturnCaseWithTwoClassItems()
            {
                var f = new ClassesControllerFixture(Db);
                var setupData = f.SetupData(allowSubClass: 2m);
                
                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                    .WithClass("C1", "I1").WithAllowSubClass(setupData.propertyType)
                    .Build();
                
                new CaseClassItem(@case.Id, setupData.definedItemDefault01.Id).In(Db);
                new CaseClassItem(@case.Id, setupData.undefinedItem01.Id).In(Db);

                var r = f.Subject.CaseClassesSummary(@case.Id);

                Assert.Equal(r.TotalItem, 2);
            }

            [Fact]
            public void ShouldReturnCaseWithZeroClassItems()
            {
                var f = new ClassesControllerFixture(Db);
                f.SetupData();

                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                    .WithClass("C1", "I1")
                    .Build();

                var r = f.Subject.CaseClassesSummary(@case.Id);

                Assert.Equal(r.TotalItem, 0);
            }
        }

        public class CaseClassesDetailsMethod : FactBase
        {
            [Fact]
            public void ShouldReturnPagedResultsForClassDetails()
            {
                var f = new ClassesControllerFixture(Db);
                f.SetupData();

                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                    .WithClass("02,46,21", "I02,I46,I21")
                    .Build();

                var tmClass02 = new TmClass(@case.CountryId, "02", @case.PropertyTypeId)
                {
                    IntClass = "I02"
                };
                var tmClass46 = new TmClass(@case.CountryId, "46", @case.PropertyTypeId, 1)
                {
                    IntClass = "I46"
                };
                var tmClass21 = new TmClass(@case.CountryId, "21", @case.PropertyTypeId, 2)
                {
                    IntClass = "I21"
                };

                var tmClasses = new[] {tmClass02, tmClass46, tmClass21};

                f.CaseClasses.Get(@case).Returns(tmClasses);

                var firstInUse02 = new ClassFirstUse(@case.Id, "02")
                {
                    FirstUsedDate = DateTime.Today.AddDays(-2),
                    FirstUsedInCommerceDate = DateTime.Today.AddDays(-4)
                }.In(Db);

                f.ClassesTextResolver.Resolve("02", @case.Id).Returns(new {GsText = "Case Text in default language for Class 02", HasMultipleLanguageClassText = false});
                f.ClassesTextResolver.Resolve("46", @case.Id).Returns(new {GsText = "Case Text in default language for Class 46", HasMultipleLanguageClassText = false});
                f.ClassesTextResolver.Resolve("21", @case.Id).Returns(new {GsText = "Case Text in default language for Class 21", HasMultipleLanguageClassText = false});

                var result = f.Subject.CaseClassesDetails(@case.Id, new CommonQueryParameters());
                
                Assert.Equal(3, result.Data.Count());
                Assert.Equal(tmClass02.Class, ((IEnumerable<dynamic>)result.Data).First().Class);
                Assert.Equal(firstInUse02.FirstUsedDate, ((IEnumerable<dynamic>)result.Data).First().DateFirstUse);
                Assert.Equal(tmClass46.Class, ((IEnumerable<dynamic>)result.Data).Last().Class);
            }
        }
    }

    public class ClassesControllerFixture : IFixture<ClassesController>
    {
        readonly InMemoryDbContext _db;
        
        public ClassesControllerFixture(InMemoryDbContext db)
        {
            _db = db;

            ClassesTextResolver = Substitute.For<IClassesTextResolver>();
            CaseClasses = Substitute.For<ICaseClasses>();
            QueryService = Substitute.For<ICommonQueryService>();
            CaseTextSection = Substitute.For<ICaseTextSection>();

            Subject = new ClassesController(_db, QueryService, CaseClasses, ClassesTextResolver, CaseTextSection);
        }

        public ClassesController Subject { get; }

        public IClassesTextResolver ClassesTextResolver { get; set; }
        public ICommonQueryService QueryService;
        public ICaseClasses CaseClasses;
        public ICaseTextSection CaseTextSection { get; set; }

        public dynamic SetupData(decimal allowSubClass = 0m)
        {
            var propertyType = new PropertyTypeBuilder
            {
                AllowSubClass = allowSubClass,
                Id = "T",
                Name = "Trademark"
            }.Build().In(_db);

            var germanTableCode = new TableCodeBuilder
            {
                Description = "German",
                TableCode = Fixture.Integer(),
                TableType = (short)TableTypes.Language,
                UserCode = null
            }.Build().In(_db);

            var frenchTableCode = new TableCodeBuilder
            {
                Description = "French",
                TableCode = Fixture.Integer(),
                TableType = (short)TableTypes.Language,
                UserCode = null
            }.Build().In(_db);

            var class01 = new TmClass("AF", "01", propertyType.Name).In(_db);
            var class01B = new TmClass("AF", "01", propertyType.Name, 1) { SubClass = "B" }.In(_db);

            var undefinedItem01 = new ClassItem("Undefined01", "Undefined Item for class 01", null, class01.Id)
            {
                Class = class01,
                Language = null
            }.In(_db);

            var definedItemDefault01 = new ClassItem("Item01B", "Item01 for Class 01 SubClass B", null, class01B.Id)
            {
                Class = class01B,
                Language = null
            }.In(_db);

            var definedItemGerman01 = new ClassItem("Item01B", "Item01 in German for Class 01 SubClass B", germanTableCode.Id, class01B.Id)
            {
                Class = class01B,
                Language = germanTableCode
            }.In(_db);

            var definedItemFrench01 = new ClassItem("Item01B", "Item01 in French for Class 01 SubClass B", frenchTableCode.Id, class01B.Id)
            {
                Class = class01B,
                Language = frenchTableCode
            }.In(_db);

            return new
            {
                class01,
                class01B,
                undefinedItem01,
                definedItemDefault01,
                definedItemGerman01,
                definedItemFrench01,
                germanTableCode,
                frenchTableCode,
                propertyType
            };
        }
    }
}
