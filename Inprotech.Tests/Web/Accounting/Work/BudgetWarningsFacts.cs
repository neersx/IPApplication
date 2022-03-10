using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class BudgetWarningsFacts
    {
        public class For : FactBase
        {
            [Fact]
            public async Task ReturnsNullForNoBudget()
            {
                var test = new CaseBuilder().Build().In(Db);
                var f = new BudgetWarningsFixture(Db);
                Assert.Null(await f.Subject.For(test.Id, Fixture.Monday));
                await f.AccountingProvider.DidNotReceive().UnbilledWipFor(Arg.Any<int>());
            }

            [Fact]
            public async Task ReturnsNullIfNoWorkHistory()
            {
                var test = new CaseBuilder {BudgetAmount = Fixture.Decimal()}.Build().In(Db);
                var f = new BudgetWarningsFixture(Db);
                Assert.Null(await f.Subject.For(test.Id, Fixture.Monday));
                await f.AccountingProvider.DidNotReceive().UnbilledWipFor(Arg.Any<int>());
            }

            [Fact]
            public async Task ReturnsNullIfWithinBudget()
            {
                var test = new CaseBuilder {BudgetAmount = 1000}.Build().In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Draft, MovementClass = MovementClass.Entered}.In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.Entered}.In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.Billed}.In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustUp}.In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustDown}.In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.Entered}.In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Draft, MovementClass = MovementClass.AdjustUp}.In(Db);
                new WorkHistory {CaseId = test.Id, LocalValue = 10, Status = TransactionStatus.Draft, MovementClass = MovementClass.AdjustDown}.In(Db);
                var f = new BudgetWarningsFixture(Db);
                Assert.Null(await f.Subject.For(test.Id, Fixture.Monday));
                await f.AccountingProvider.DidNotReceive().UnbilledWipFor(Arg.Any<int>());
            }

            [Fact]
            public async Task ReturnsWarningsWhenUsedTotalExceedsBudget()
            {
                var test = new CaseBuilder {BudgetAmount = 20, RevisedBudgetAmount = 10}.Build().In(Db);
                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Draft, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Draft, 
                    MovementClass = MovementClass.Billed, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Draft, 
                    MovementClass = MovementClass.AdjustUp, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Draft, 
                    MovementClass = MovementClass.AdjustDown, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.AdjustUp, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.AdjustDown, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed, 
                    TransDate = Fixture.Today()
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed, 
                    TransDate = Fixture.Today()
                }.In(Db);

                var f = new BudgetWarningsFixture(Db);
                f.AccountingProvider.UnbilledWipFor(test.Id).Returns((decimal) 543.21);
                var result = await f.Subject.For(test.Id, Fixture.Monday);
                await f.AccountingProvider.Received(1).UnbilledWipFor(test.Id);
                Assert.Equal(30, result.usedTotal);
                Assert.Equal((decimal) 543.21, (decimal) result.unbilledTotal);
                Assert.Equal(300, result.PercentageUsed);
                Assert.Equal(-20, result.billedTotal);
                Assert.Equal(20, result.budget.Original);
                Assert.Equal(10, result.budget.Revised);
            }

            [Fact]
            public async Task ReturnsNullIfSelectedDateOutsideBudgetDates()
            {
                var f = new BudgetWarningsFixture(Db);
                var futureStartDate = new CaseBuilder {BudgetAmount = 20, BudgetStartDate = Fixture.FutureDate()}.Build().In(Db);
                Assert.Null(await f.Subject.For(futureStartDate.Id, Fixture.Today()));

                var pastEndDate = new CaseBuilder {BudgetAmount = 20, BudgetEndDate = Fixture.PastDate()}.Build().In(Db);
                Assert.Null(await f.Subject.For(pastEndDate.Id, Fixture.Today()));

                var test = new CaseBuilder {BudgetAmount = 20, BudgetStartDate = Fixture.PastDate(), BudgetEndDate = Fixture.FutureDate()}.Build().In(Db);
                Assert.Null(await f.Subject.For(test.Id, Fixture.FutureDate().AddDays(1)));
                Assert.Null(await f.Subject.For(test.Id, Fixture.PastDate().AddDays(-1)));
            }

            [Fact]
            public async Task ReturnsWarningIfSelectedDateWithinBudgetDates()
            {
                var f = new BudgetWarningsFixture(Db);
                var test = new CaseBuilder {BudgetAmount = 20, BudgetStartDate = Fixture.PastDate(), BudgetEndDate = Fixture.FutureDate()}.Build().In(Db);

                new WorkHistory 
                {
                    CaseId = test.Id, LocalValue = 50, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.Today().AddDays(-1)
                }.In(Db);

                Assert.NotNull(await f.Subject.For(test.Id, Fixture.Today()));
            }

            [Fact]
            public async Task ReturnsNoWarningIfSiteControlHasValueAndSpecifiedPercentageIsUnderBudget()
            {
                var f = new BudgetWarningsFixture(Db);
                f.SiteControlReader.Read<int?>(SiteControls.BudgetPercentageUsed).Returns(300);
                var test = new CaseBuilder {BudgetAmount = 20, BudgetStartDate = Fixture.PastDate(), BudgetEndDate = Fixture.FutureDate()}.Build().In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, LocalValue = 50, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.Today().AddDays(-1)
                }.In(Db);

                Assert.Null(await f.Subject.For(test.Id, Fixture.Today()));
            }

            [Fact]
            public async Task ReturnsWarningIfSiteControlHasValueAndSpecifiedPercentageIsOverBudget()
            {
                var f = new BudgetWarningsFixture(Db);
                f.SiteControlReader.Read<int?>(SiteControls.BudgetPercentageUsed).Returns(10);
                var test = new CaseBuilder {BudgetAmount = 20, BudgetStartDate = Fixture.PastDate(), BudgetEndDate = Fixture.FutureDate()}.Build().In(Db);

                new WorkHistory 
                {
                    CaseId = test.Id, LocalValue = 50, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.Today().AddDays(-1)
                }.In(Db);

                Assert.NotNull(await f.Subject.For(test.Id, Fixture.Today()));
            }

            [Fact]
            public async Task IfBudgetHasDatesTotalCalculationConsidersIt()
            {
                var f = new BudgetWarningsFixture(Db);

                var test = new CaseBuilder {BudgetAmount = 20, BudgetStartDate = Fixture.PastDate(), BudgetEndDate = Fixture.FutureDate()}.Build().In(Db);
                f.AccountingProvider.UnbilledWipFor(test.Id, Fixture.PastDate(), Fixture.FutureDate()).Returns((decimal) 500.00);

                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 1, WipSequenceNo = 1, LocalValue = 50,
                    Status = TransactionStatus.Active, MovementClass = MovementClass.Entered, TransDate = Fixture.Today().AddDays(-1)
                }.In(Db);
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 2, WipSequenceNo = 1, LocalValue = 20,
                    Status = TransactionStatus.Active, MovementClass = MovementClass.Billed, TransDate = Fixture.FutureDate().AddDays(1)
                }.In(Db);
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 3, WipSequenceNo = 1, LocalValue = 30,
                    Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustUp, TransDate = Fixture.PastDate().AddDays(-1)
                }.In(Db);
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 4, WipSequenceNo = 1, LocalValue = 22,
                    Status = TransactionStatus.Active, MovementClass = MovementClass.Billed, TransDate = Fixture.Today().AddDays(1)
                }.In(Db);
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 5, WipSequenceNo = 1, LocalValue = 40,
                    Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustDown
                }.In(Db);

                var result = await f.Subject.For(test.Id, Fixture.Today());

                Assert.Equal(20, result.budget.Original);
                Assert.Equal(-22, result.billedTotal);
                Assert.Equal(50, result.usedTotal);
                Assert.Equal((decimal) 500.00, (decimal) result.unbilledTotal);
                Assert.Equal(250, result.PercentageUsed);
            }

            [Theory]
            [InlineData(true, true, -20)]
            [InlineData(true, false, -30)]
            [InlineData(false, true, -40)]
            [InlineData(false, false, -50)]
            public async Task ReturnsBilledToDateWithinBudgetDateRange(bool withStart, bool withEnd, decimal expected)
            {
                var f = new BudgetWarningsFixture(Db);

                var test = new CaseBuilder {BudgetAmount = 1, BudgetStartDate = withStart ? Fixture.PastDate() : null, BudgetEndDate = withEnd ? Fixture.FutureDate() : null}.Build().In(Db);
                f.AccountingProvider.UnbilledWipFor(test.Id, Arg.Any<DateTime>(), Arg.Any<DateTime>()).Returns((decimal) 500.00);

                // created before start, billed today
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 1, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.PastDate().AddDays(-1)
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 1, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed,
                    TransDate = Fixture.Today()
                }.In(Db);

                // created within range, billed within range
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 2, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.PastDate().AddDays(1)
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 2, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed, 
                    TransDate = Fixture.Today()
                }.In(Db);

                // no created date, billed today
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 3, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 3, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed,
                    TransDate = Fixture.Today()
                }.In(Db);

                // created and billed in past
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 4, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.PastDate().AddDays(-1)
                }.In(Db);

                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 4, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed, 
                    TransDate = Fixture.PastDate().AddDays(-1)
                }.In(Db);

                // created and billed in future
                new WorkHistory
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 5, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Entered, 
                    TransDate = Fixture.FutureDate().AddDays(1)
                }.In(Db);

                new WorkHistory 
                {
                    CaseId = test.Id, EntityId = 1, TransactionId = 5, WipSequenceNo = 1, LocalValue = 10, 
                    Status = TransactionStatus.Active, 
                    MovementClass = MovementClass.Billed, 
                    TransDate = Fixture.FutureDate().AddDays(1)
                }.In(Db);

                var result = await f.Subject.For(test.Id, Fixture.Today());
                Assert.Equal(expected, result.billedTotal);
            }
        }

        class BudgetWarningsFixture : IFixture<BudgetWarnings>
        {
            public BudgetWarningsFixture(InMemoryDbContext db)
            {
                SiteControlReader = Substitute.For<ISiteControlReader>();
                AccountingProvider = Substitute.For<IAccountingProvider>();
                Subject = new BudgetWarnings(db, AccountingProvider, SiteControlReader);
            }

            public ISiteControlReader SiteControlReader { get; }
            public IAccountingProvider AccountingProvider { get; }
            public BudgetWarnings Subject { get; }
        }
    }
}