using System;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Wip
{
    public class ValidatePostDatesFacts
    {
        public class ForMethod : FactBase
        {
            [Fact]
            public async Task ReturnsErrorIsAllPeriodsAreClosedForTheModule()
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling}.Build().In(Db);
                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.For(Fixture.Today());
                Assert.Equal(KnownErrors.CouldNotDeterminePostPeriod, result.code);
                Assert.False(result.isValid);
                Assert.False(result.isWarningOnly);
            }

            [Fact]
            public async Task ReturnsTrueWhenPeriodIsFound()
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling, StartDate = Fixture.PastDate().AddDays(-10), EndDate = Fixture.PastDate()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.PastDate(), EndDate = Fixture.FutureDate(), PostingCommenced = Fixture.PastDate()}.Build().In(Db);
                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.For(Fixture.Today());
                Assert.Equal(string.Empty,result.code);
                Assert.True(result.isValid);
                Assert.False(result.isWarningOnly);
            }

            [Fact]
            public async Task ReturnsErrorWhenAttemptingToPostToFutureDateToCurrentPeriod()
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling, StartDate = Fixture.PastDate().AddDays(-10), EndDate = Fixture.PastDate()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.Today().AddDays(-10), EndDate = Fixture.Today().AddDays(10), PostingCommenced = Fixture.Today().AddDays(-10)}.Build().In(Db);
                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.For(Fixture.Today().AddDays(1));
                Assert.Equal(KnownErrors.CannotPostFutureDate, result.code);
                Assert.False(result.isValid);
                Assert.False(result.isWarningOnly);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsValidWhenPostingToDifferentPeriod(bool withPostingCommenced)
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling, StartDate = Fixture.PastDate().AddDays(-10), EndDate = Fixture.PastDate()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.Today().AddDays(-60), EndDate = Fixture.Today().AddDays(-30), PostingCommenced = Fixture.Today()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.Today().AddDays(-30), EndDate = Fixture.Today(), PostingCommenced = withPostingCommenced ? Fixture.Today() : (DateTime?) null}.Build().In(Db);
                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.For(Fixture.Today());
                Assert.True(result.isValid);
                Assert.False(result.isWarningOnly);
                Assert.Equal(string.Empty, result.code);
            }

            [Fact]
            public async Task ReturnsErrorWhenNoPeriodFound()
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling, StartDate = Fixture.PastDate().AddDays(-10), EndDate = Fixture.PastDate()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.PastDate().AddDays(-30), EndDate = Fixture.PastDate()}.Build().In(Db);
                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.For(Fixture.Today());
                Assert.Equal(KnownErrors.CouldNotDeterminePostPeriod, result.code);
                Assert.False(result.isValid);
                Assert.False(result.isWarningOnly);
            }

            [Fact]
            public async Task ReturnsWarningIfPostingToNextOpenPeriod()
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling, StartDate = Fixture.PastDate().AddDays(-10), EndDate = Fixture.PastDate()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.Today().AddDays(-60), EndDate = Fixture.Today().AddDays(-30), PostingCommenced = Fixture.PastDate()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.Today().AddDays(-30), EndDate = Fixture.Today(), PostingCommenced = Fixture.PastDate(), ClosedForModules = SystemIdentifier.TimeAndBilling}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.Today().AddDays(1), EndDate = Fixture.Today().AddDays(30)}.Build().In(Db);
                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.For(Fixture.Today());
                Assert.Equal(KnownErrors.ItemPostedToDifferentPeriod, result.code);
                Assert.False(result.isValid);
                Assert.True(result.isWarningOnly);
            }

            [Fact]
            public async Task ReturnsErrorWhenAttemptingToPostToFutureDateInTransactionalPeriod()
            {
                new PeriodBuilder
                {
                    StartDate = Fixture.Today().AddDays(-1), 
                    EndDate = Fixture.Today().AddDays(30)
                }.Build().In(Db);

                var futureDate = Fixture.Today().AddDays(1);

                var f = new ValidatePostDatesFixture(Db);
                
                var result = await f.Subject.For(futureDate);
                Assert.Equal(KnownErrors.CannotPostFutureDate, result.code);
                Assert.False(result.isValid);
                Assert.False(result.isWarningOnly);
            }
        }

        public class GetMinOpenPeriodFor : FactBase
        {
            [Fact]
            public async Task ShouldReturnMinOpenPeriodForGivenDate()
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling, StartDate = Fixture.Today().AddDays(-10), EndDate = Fixture.Today().AddDays(5)}.Build().In(Db);
                var p1 = new PeriodBuilder {StartDate = Fixture.Today().AddDays(30), EndDate = Fixture.Today().AddDays(59), PostingCommenced = Fixture.PastDate()}.Build().In(Db);
                new PeriodBuilder {StartDate = Fixture.Today().AddDays(60), EndDate = Fixture.Today().AddDays(90), PostingCommenced = Fixture.PastDate()}.Build().In(Db);

                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.GetMinOpenPeriodFor(Fixture.Today());
                Assert.Equal(p1.StartDate, result.StartDate);
                Assert.Equal(p1.EndDate, result.EndDate);
                Assert.Equal(p1.PostingCommenced, result.PostingCommenced);
            }

            [Fact]
            public async Task ShouldReturnNullWhenNoOpenPeriodFound()
            {
                new PeriodBuilder {ClosedForModules = SystemIdentifier.TimeAndBilling, StartDate = Fixture.Today().AddDays(-10), EndDate = Fixture.Today().AddDays(5)}.Build().In(Db);
                var p1 = new PeriodBuilder {StartDate = Fixture.Today().AddDays(30), EndDate = Fixture.Today().AddDays(59), PostingCommenced = Fixture.PastDate(), ClosedForModules = SystemIdentifier.TimeAndBilling}.Build().In(Db);

                var f = new ValidatePostDatesFixture(Db);
                var result = await f.Subject.GetMinOpenPeriodFor(Fixture.Today());
                Assert.Null(result);
            }
        }  

        public class ValidatePostDatesFixture : IFixture<ValidatePostDates>
        {
            public ValidatePostDatesFixture(InMemoryDbContext db)
            {
                Now = Substitute.For<Func<DateTime>>();
                Now().Returns(Fixture.Today());
                Subject = new ValidatePostDates(db, Now);
            }

            Func<DateTime> Now { get; }
            public ValidatePostDates Subject { get; }
        }
    }
}