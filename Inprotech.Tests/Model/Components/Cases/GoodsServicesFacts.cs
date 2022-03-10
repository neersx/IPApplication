using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class GoodsServicesFacts
    {
        public class DoesClassExistsMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseIfClassDoesNotExists()
            {
                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                            .WithClass("09", "09")
                            .Build();

                var f = new GoodsServicesFixture(Db);

                var result = f.Subject.DoesClassExists(@case, "90");

                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfClassExists()
            {
                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                            .WithClass("09", "09")
                            .Build();

                var f = new GoodsServicesFixture(Db);

                var result = f.Subject.DoesClassExists(@case, "09");

                Assert.True(result);
            }
        }

        public class AddClassMethod : FactBase
        {
            [Fact]
            public void ExistingLocalClassUsed()
            {
                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                            .WithClass("09", "09")
                            .Build();

                var f = new GoodsServicesFixture(Db);

                f.Subject.AddClass(@case, "09");

                f.Classes.Received(1).GetLocalClass(Arg.Is("T"), Arg.Is("AU"), Arg.Is("09"));

                Assert.Equal("09", @case.LocalClasses);
            }

            [Fact]
            public void LocalClassIsAdded()
            {
                var @case = new InprotechCaseBuilder(Db, "AU", "T")
                    .Build();

                var localClassesValue = @case.LocalClasses;

                var f = new GoodsServicesFixture(Db);

                f.Subject.AddClass(@case, "90");

                f.Classes.Received(1).GetLocalClass(Arg.Is("T"), Arg.Is("AU"), Arg.Is("90"));

                Assert.NotEqual(localClassesValue, @case.LocalClasses);
            }
        }

        public class AddOrUpdateMethod : FactBase
        {
            [Fact]
            public void CaseTextIsAddedWhenHistoryTobeKept()
            {
                const string newText = "Goods and Service for Class 09";
                var @case = new InprotechCaseBuilder(Db)
                            .WithClass("09", "09")
                            .WithCaseText("09", "old")
                            .Build();

                var f = new GoodsServicesFixture(Db)
                    .WithSiteControl();

                f.Subject.AddOrUpdate(@case, "09", newText);

                Assert.Equal(2, @case.CaseTexts.Count);

                var addedText = @case.CaseTexts.OrderByDescending(_ => _.Number ?? 0).First();
                Assert.Equal((short) 1, addedText.Number);
                Assert.Equal(newText, addedText.Text);
                Assert.Equal(0, addedText.IsLongText);
                Assert.Null(addedText.Language);
            }

            [Fact]
            public void CaseTextIsAddedWhenNotPresent()
            {
                const string newText = "Goods and Service for Class 09";
                var @case = new InprotechCaseBuilder(Db)
                            .WithClass("09", "09")
                            .Build();

                var f = new GoodsServicesFixture(Db)
                    .WithSiteControl();

                f.Subject.AddOrUpdate(@case, "09", newText);

                Assert.Equal(1, @case.CaseTexts.Count);

                var addedText = @case.CaseTexts.First();
                Assert.Equal((short) 0, addedText.Number);
                Assert.Equal(newText, addedText.Text);
                Assert.Equal(0, addedText.IsLongText);
                Assert.Null(addedText.Language);
            }

            [Fact]
            public void CaseTextIsUpdated()
            {
                const string newText = "Goods and Service for Class 09";
                var @case = new InprotechCaseBuilder(Db)
                            .WithClass("09", "09")
                            .WithCaseText("09", "old")
                            .Build();

                var f = new GoodsServicesFixture(Db)
                    .WithSiteControl(false);

                f.Subject.AddOrUpdate(@case, "09", newText);

                Assert.Equal(1, @case.CaseTexts.Count);

                var addedText = @case.CaseTexts.First();
                Assert.Equal((short) 0, addedText.Number);
                Assert.Equal(newText, addedText.Text);
                Assert.Equal(0, addedText.IsLongText);
                Assert.Null(addedText.Language);
            }

            [Fact]
            public void FirstUseDatesAdded()
            {
                var @case = new InprotechCaseBuilder(Db)
                            .WithClass("09", "09")
                            .Build();

                var f = new GoodsServicesFixture(Db)
                    .WithSiteControl();

                f.Subject.AddOrUpdate(@case, "09", null, null, Fixture.FutureDate(), Fixture.PastDate());

                var firstUseRecord = @case.ClassFirstUses.First(_ => _.CaseId == @case.Id && _.Class == "09");

                Assert.Equal(Fixture.FutureDate(), firstUseRecord.FirstUsedDate);
                Assert.Equal(Fixture.PastDate(), firstUseRecord.FirstUsedInCommerceDate);
            }

            [Fact]
            public void FirstUseDatesUpdated()
            {
                var @case = new InprotechCaseBuilder(Db)
                            .WithClass("09", "09")
                            .WithClassFirstUse("09", "12/12/2014", "12/12/2014")
                            .Build();

                var f = new GoodsServicesFixture(Db)
                    .WithSiteControl();

                f.Subject.AddOrUpdate(@case, "09", null, null, Fixture.FutureDate(), Fixture.PastDate());

                var firstUseRecord = @case.ClassFirstUses.First(_ => _.CaseId == @case.Id && _.Class == "09");

                Assert.Equal(Fixture.FutureDate(), firstUseRecord.FirstUsedDate);
                Assert.Equal(Fixture.PastDate(), firstUseRecord.FirstUsedInCommerceDate);
            }

            [Fact]
            public void ThrowsExceptionIfClassNotPresent()
            {
                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                var f = new GoodsServicesFixture(Db)
                    .WithSiteControl();

                var ex = Record.Exception(() => f.Subject.AddOrUpdate(@case, "09", "new"));

                Assert.Equal("Local class does not exists for the case. Class - 09", ex.Message);
            }
        }
    }

    internal class GoodsServicesFixture : IFixture<IGoodsServices>
    {
        readonly InMemoryDbContext _db;

        public GoodsServicesFixture(InMemoryDbContext db)
        {
            _db = db;
            Classes = Substitute.For<IClasses>();
            Classes.GetLocalClass(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>()).Returns(x => new TmClass((string) x[1], (string) x[2], (string) x[0]).In(db));

            SiteConfiguration = new SiteConfiguration(db);

            Subject = new GoodsServices(Classes, SiteConfiguration, Fixture.Today);
        }

        public IClasses Classes { get; }

        public ISiteConfiguration SiteConfiguration { get; }
        public IGoodsServices Subject { get; }

        public GoodsServicesFixture WithSiteControl(bool keepSpecHistory = true)
        {
            _db.Set<SiteControl>().Add(new SiteControl(SiteControls.KEEPSPECIHISTORY, keepSpecHistory));

            return this;
        }
    }
}