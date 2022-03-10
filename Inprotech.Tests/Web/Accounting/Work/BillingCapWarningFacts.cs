using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class BillingCapWarningFacts
    {
        public class ForCase : FactBase
        {
            dynamic SetupCase(decimal? billingCap, decimal totalBilled, bool withMultipleExceeded = false)
            {
                var @case = new CaseBuilder().BuildWithId(Fixture.Integer());
                var nameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var debtor = new CaseNameBuilder(Db) {NameType = nameType, Name = name}.BuildWithCase(@case).In(Db);
                new ClientDetailBuilder().WithBillingCap(billingCap, Fixture.Monday, 1, KnownPeriodTypes.Days, true)
                                         .BuildForName(debtor.Name).In(Db);

                var name2 = new NameBuilder(Db).Build().In(Db);
                var debtor2 = new CaseNameBuilder(Db) {NameType = nameType, Name = name2}.BuildWithCase(@case).In(Db);
                new ClientDetailBuilder().WithBillingCap(billingCap, Fixture.Monday, 1, KnownPeriodTypes.Days, true)
                                         .BuildForName(debtor2.Name).In(Db);
                new OpenItemBuilder(Db)
                {
                    LocalValue = totalBilled,
                    TypeId = ItemType.DebitNote,
                    Status = TransactionStatus.Active,
                    AccountDebtorName = debtor.Name,
                    PostDate = Fixture.Tuesday
                }.BuildWithCase(@case);

                if (withMultipleExceeded)
                {
                    new OpenItemBuilder(Db)
                    {
                        LocalValue = totalBilled,
                        TypeId = ItemType.DebitNote,
                        Status = TransactionStatus.Active,
                        AccountDebtorName = debtor2.Name,
                        PostDate = Fixture.Tuesday
                    }.BuildWithCase(@case);
                }

                return new {Case = @case, Debtor = debtor, Debtor2 = debtor2};
            }

            [Theory]
            [InlineData(null)]
            [InlineData(0)]
            public async Task ReturnsNullIfInstructorHasNoBillingCap(decimal billingCap)
            {
                var @case = SetupCase(billingCap, Fixture.Decimal());
                var f = new BillingCapCheckFixture(Db);
                var result = await f.Subject.ForCase(@case.Case.Id, Fixture.Monday);
                Assert.Null(result);
            }

            [Fact]
            public async Task ReturnsNullIfCaseDoesNotExist()
            {
                var f = new BillingCapCheckFixture(Db);
                var result = await f.Subject.ForCase(Fixture.Integer(), Fixture.Monday);
                Assert.Null(result);
            }

            [Fact]
            public async Task ReturnsNullIfBillingCapNotExceeded()
            {
                var billingCap = Fixture.Decimal();
                var @case = SetupCase(billingCap, billingCap);
                var f = new BillingCapCheckFixture(Db);
                var result = await f.Subject.ForCase(@case.Case.Id, Fixture.Tuesday);
                Assert.Null(result);
            }

            [Fact]
            public async Task ReturnsBillingCapDataForDebtorWhenExceeded()
            {
                var billingCap = Fixture.Decimal();
                var @case = SetupCase(billingCap, billingCap + 1);
                var f = new BillingCapCheckFixture(Db);
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        @case.Debtor.NameId, new NameFormatted {Name = $"Formatted, ABC"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).ReturnsForAnyArgs(formatted);
                var result = await f.Subject.ForCase(@case.Case.Id, Fixture.Tuesday);
                Assert.Equal(billingCap, result[0].Value);
                Assert.Equal(Fixture.Monday, result[0].StartDate);
                Assert.Equal(1, result[0].Period);
                Assert.Equal(KnownPeriodTypes.Days, result[0].PeriodType);
                Assert.True(result[0].IsRecurring);
                Assert.Equal(billingCap + 1, result[0].TotalBilled);
            }
            [Fact]
            public async Task ReturnsBillingCapDataForMultipleDebtorsWhenExceeded()
            {
                var billingCap = Fixture.Decimal();
                var @case = SetupCase(billingCap, billingCap + 1, withMultipleExceeded: true);
                var f = new BillingCapCheckFixture(Db);
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        @case.Debtor.NameId, new NameFormatted {Name = "Formatted, ABC"}
                    },
                    {
                        @case.Debtor2.NameId, new NameFormatted {Name = "Formatted, XYZ"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).ReturnsForAnyArgs(formatted);
                var result = await f.Subject.ForCase(@case.Case.Id, Fixture.Tuesday);
                Assert.Equal(billingCap, result[0].Value);
                Assert.Equal(Fixture.Monday, result[0].StartDate);
                Assert.Equal(1, result[0].Period);
                Assert.Equal(KnownPeriodTypes.Days, result[0].PeriodType);
                Assert.True(result[0].IsRecurring);
                Assert.Equal(billingCap + 1, result[0].TotalBilled);
                Assert.Equal("Formatted, ABC", result[0].DebtorName);
                Assert.Equal(billingCap, result[1].Value);
                Assert.Equal(Fixture.Monday, result[1].StartDate);
                Assert.Equal(1, result[1].Period);
                Assert.Equal(KnownPeriodTypes.Days, result[1].PeriodType);
                Assert.True(result[1].IsRecurring);
                Assert.Equal(billingCap + 1, result[1].TotalBilled);
                Assert.Equal("Formatted, XYZ", result[1].DebtorName);
            }
        }

        public class ForName : FactBase
        {
            Name SetupName(decimal billingCap, decimal totalBilled, bool isRecurring = true)
            {
                var name = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder().WithBillingCap(billingCap, Fixture.PastDate(), 1, KnownPeriodTypes.Days, isRecurring)
                                         .BuildForName(name).In(Db);
                new OpenItemBuilder(Db)
                {
                    LocalValue = totalBilled,
                    TypeId = ItemType.DebitNote,
                    Status = TransactionStatus.Active,
                    AccountDebtorName = name,
                    PostDate = Fixture.Today()
                }.Build().In(Db);

                return name;
            }

            [Fact]
            public async Task ReturnsNullIfBillingCapIsNotConfigured()
            {
                var f = new BillingCapCheckFixture(Db);
                var result = await f.Subject.ForName(Fixture.Integer(), Fixture.Today());
                Assert.Null(result);
            }

            [Theory]
            [InlineData(null)]
            [InlineData(0)]
            public async Task ReturnsNullIfDebtorHasNoBillingCap(decimal billingCap)
            {
                var name = SetupName(billingCap, Fixture.Decimal());
                var f = new BillingCapCheckFixture(Db);
                var result = await f.Subject.ForName(name.Id, Fixture.Today());
                Assert.Null(result);
            }

            [Fact]
            public async Task ReturnsNullIfBillingCapNotExceeded()
            {   
                var billingCap = Fixture.Decimal();
                var name = SetupName(billingCap, billingCap);
                var f = new BillingCapCheckFixture(Db);
                Assert.True(Db.Set<OpenItemCase>().Any());
                Assert.True(Db.Set<OpenItem>().Any(_ => _.AccountDebtorId == name.Id));
                var result = await f.Subject.ForName(name.Id, Fixture.Today());
                Assert.Null(result);
            }

            [Fact]
            public async Task ReturnsBillingCapDataForDebtorWhenExceeded()
            {
                var billingCap = Fixture.Decimal();
                var name = SetupName(billingCap, billingCap + 1);
                var f = new BillingCapCheckFixture(Db);
                Assert.True(Db.Set<OpenItemCase>().Any());
                Assert.True(Db.Set<OpenItem>().Any(_ => _.AccountDebtorId == name.Id));
                var result = await f.Subject.ForName(name.Id, Fixture.Today());
                Assert.Equal(billingCap, result.Value);
                Assert.Equal(Fixture.PastDate(), result.StartDate);
                Assert.Equal(1, result.Period);
                Assert.Equal(KnownPeriodTypes.Days, result.PeriodType);
                Assert.True(result.IsRecurring);
                Assert.Equal(billingCap + 1, result.TotalBilled);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsBillingCapDataForDebtorWhenApproachingPercentage(bool isApproaching)
            {
                const int billingCap = 1000;
                const int billingCapPercent = 90;
                var totalBilled = billingCap * ((isApproaching ? (decimal)billingCapPercent : 10) / 100) + 1;
                var name = SetupName(billingCap, totalBilled);
                var f = new BillingCapCheckFixture(Db);
                f.SiteControlReader.Read<int?>(SiteControls.BillingCapThresholdPercent).Returns(isApproaching ? billingCapPercent : 10);
                var result = await f.Subject.ForName(name.Id, Fixture.Today());
                if (isApproaching)
                {
                    Assert.Equal(billingCap, result.Value);
                    Assert.Equal(Fixture.PastDate(), result.StartDate);
                    Assert.Equal(1, result.Period);
                    Assert.Equal(KnownPeriodTypes.Days, result.PeriodType);
                    Assert.True(result.IsRecurring);
                    Assert.Equal(totalBilled, result.TotalBilled);
                }
                else
                {
                    Assert.Null(result);
                }
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsNullIfNotBilledWithinCapPeriod(bool isRecurring)
            {
                const int billingCap = 1000;
                const decimal totalBilled = billingCap + 1;
                var name = SetupName(billingCap, totalBilled, isRecurring);
                new OpenItemBuilder(Db)
                {
                    LocalValue = billingCap,
                    TypeId = ItemType.DebitNote,
                    Status = TransactionStatus.Active,
                    AccountDebtorName = name,
                    PostDate = Fixture.PastDate()
                }.Build().In(Db);
                var f = new BillingCapCheckFixture(Db);
                var result = await f.Subject.ForName(name.Id, Fixture.Today());
                if (isRecurring)
                { 
                    Assert.Equal(billingCap, result.Value);
                    Assert.Equal(Fixture.PastDate(), result.StartDate);
                    Assert.Equal(1, result.Period);
                    Assert.Equal(KnownPeriodTypes.Days, result.PeriodType);
                    Assert.True(result.IsRecurring);
                    Assert.Equal(totalBilled, result.TotalBilled);
                }
                else
                {
                    Assert.Null(result);
                }
            }
        }

        public class BillingCapCheckFixture : IFixture<BillingCapCheck>
        {
            public BillingCapCheckFixture(InMemoryDbContext db)
            {
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.Read<int>(SiteControls.BillingCapThresholdPercent).Returns(50);
                Now = Substitute.For<Func<DateTime>>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                DisplayFormattedName.For(Arg.Any<int>()).ReturnsForAnyArgs("formatted-debtor-name");
                Subject = new BillingCapCheck(db, SiteControlReader, Now, DisplayFormattedName);
                new OpenItemCase
                {
                    ItemEntityId = Fixture.Integer(),
                    ItemTransactionId = Fixture.Integer(),
                    AccountEntityId = Fixture.Integer(),
                    AccountDebtorId = Fixture.Integer(),
                    LocalValue = Fixture.Integer(),
                    Status = TransactionStatus.Draft
                }.In(db);
            }

            public ISiteControlReader SiteControlReader { get; set; }
            public Func<DateTime> Now { get; set; }
            public IDisplayFormattedName DisplayFormattedName { get; set; }
            public BillingCapCheck Subject { get; }
        }
    }
}