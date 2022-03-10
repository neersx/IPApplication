using System;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.BulkBilling;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using ServiceStack;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing
{
    public class ValidateTransactionDatesFacts
    {
        readonly BillDateSetting _billDateSetting = new();
        readonly BillingSiteSettings _billingSiteSettings = new();
        readonly IValidatePostDates _validatePostDates = Substitute.For<IValidatePostDates>();

        ValidateTransactionDates CreateSubject(params OpenPeriod[] openPeriods)
        {
            var billingSiteSettingsResolver = Substitute.For<IBillingSiteSettingsResolver>();
            billingSiteSettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                                       .Returns(_billingSiteSettings);

            var billDateSettingsResolver = Substitute.For<IBillDateSettingsResolver>();
            billDateSettingsResolver.Resolve()
                                    .Returns(_billDateSetting);

            _validatePostDates.GetOpenPeriodsFor()
                              .Returns(openPeriods.ToArray());

            _validatePostDates.GetMinOpenPeriodFor(Arg.Any<DateTime>()).Returns( openPeriods.Length > 0 ? openPeriods[0] : null);

            return new ValidateTransactionDates(_validatePostDates, billingSiteSettingsResolver, billDateSettingsResolver, Fixture.Today);
        }

        [Fact]
        public async Task ShouldReturnErrorItemDateNotProvided()
        {
            var subject = CreateSubject();

            var result = await subject.For(null);

            Assert.False(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Equal(KnownErrors.ItemDateNotProvided, result.code);
        }

        [Theory]
        [InlineData(BillDateRestriction.OnlyFutureBillDateWithinAnyOpenPeriodAllowed)]
        [InlineData(BillDateRestriction.OnlyFutureBillDateWithinSamePeriodAsTodayAllowed)]
        [InlineData(BillDateRestriction.OnlyFutureBillDateWithinCurrentOpenPeriodAllowed)]
        public async Task ShouldReturnErrorIfTransactionDateIsInThePastBasedWhenTheseRestrictionsAreInPlace(BillDateRestriction restriction)
        {
            /* these are set when 'Bill Date Only From Today' is true */
            _billingSiteSettings.BillDateRestriction = restriction;

            var subject = CreateSubject();

            var result = await subject.For(Fixture.PastDate());

            Assert.False(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Equal(KnownErrors.BillDatesInThePastNotAllowed, result.code);
        }

        [Fact]
        public async Task ShouldReturnValidIfTransactionDateIsInTheFutureAndBillDateOnlyFromTodayIsSet()
        {
            /* these are set when 'Bill Date Only From Today' is true */
            _billingSiteSettings.BillDateRestriction = BillDateRestriction.PastAndFutureBillDatesWithinCurrentOpenPeriodAllowed;
            _validatePostDates.For(Arg.Any<DateTime>())
                              .Returns((true, true, null));

            var openPeriod = new OpenPeriod
            {
                StartDate = Fixture.Today(),
                EndDate = Fixture.FutureDate()
            };

            var subject = CreateSubject(openPeriod);

            var result = await subject.For(Fixture.FutureDate());

            Assert.True(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Null(result.code);
        }

        [Fact]
        public async Task ShouldReturnErrorIfTransactionDateIsInTheFutureButNotWithinCurrentPeriod()
        {
            _billingSiteSettings.BillDateRestriction = BillDateRestriction.OnlyFutureBillDateWithinCurrentOpenPeriodAllowed;

            var currentOpenPeriod = new OpenPeriod
            {
                StartDate = Fixture.PastDate(),
                EndDate = Fixture.Today().AddDays(5)
            };

            var nextOpenPeriod = new OpenPeriod
            {
                StartDate = Fixture.Today().AddDays(6),
                EndDate = Fixture.Today().AddDays(10)
            };

            var transactionDateInNextOpenPeriod = Fixture.Today().AddDays(7);

            var subject = CreateSubject(currentOpenPeriod, nextOpenPeriod);

            var result = await subject.For(transactionDateInNextOpenPeriod);

            Assert.False(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Equal(KnownErrors.CannotPostFutureDate, result.code);
        }

        [Fact]
        public async Task ShouldReturnValidIfTransactionDateIsInTheFutureButWithinCurrentPeriod()
        {
            _billingSiteSettings.BillDateRestriction = BillDateRestriction.OnlyFutureBillDateWithinCurrentOpenPeriodAllowed;
            _validatePostDates.For(Arg.Any<DateTime>())
                              .Returns((true, true, null));

            var currentOpenPeriod = new OpenPeriod
            {
                StartDate = Fixture.PastDate(),
                EndDate = Fixture.FutureDate()
            };

            var transactionDateInCurrentPeriod = Fixture.Today();

            var subject = CreateSubject(currentOpenPeriod);

            var result = await subject.For(transactionDateInCurrentPeriod);

            Assert.True(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Null(result.code);
        }

        [Fact]
        public async Task ShouldReturnErrorIfTransactionDateIsInFutureButNotInTheSamePeriodThatTodayFallsUnder()
        {
            _billingSiteSettings.BillDateRestriction = BillDateRestriction.OnlyFutureBillDateWithinSamePeriodAsTodayAllowed;

            var currentOpenPeriod = new OpenPeriod
            {
                StartDate = Fixture.PastDate(),
                EndDate = Fixture.Today().AddDays(5)
            };

            var nextOpenPeriod = new OpenPeriod
            {
                StartDate = Fixture.Today().AddDays(6),
                EndDate = Fixture.Today().AddDays(10)
            };

            var transactionDateInNextOpenPeriod = Fixture.Today().AddDays(7);

            var subject = CreateSubject(currentOpenPeriod, nextOpenPeriod);

            var result = await subject.For(transactionDateInNextOpenPeriod);

            Assert.False(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Equal(KnownErrors.FutureBillDatesAllowedIfDateWithinCurrentPeriod, result.code);
        }

        [Fact]
        public async Task ShouldReturnErrorIfTransactionDateIsInFutureButThereAreNoOpenPeriods()
        {
            _billingSiteSettings.BillDateRestriction = BillDateRestriction.OnlyFutureBillDateWithinAnyOpenPeriodAllowed;

            var currentOpenPeriod = new OpenPeriod
            {
                StartDate = Fixture.PastDate(),
                EndDate = Fixture.Today()
            };

            var subject = CreateSubject(currentOpenPeriod);

            var result = await subject.For(Fixture.FutureDate());

            Assert.False(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Equal(KnownErrors.ItemDateCannotBeInFuturePeriodThatIsClosedForModule, result.code);
        }

        [Fact]
        public async Task ShouldThrowWarningIfCurrentPeriodIsClosed()
        {
            var nextOpenPeriod = new OpenPeriod
            {
                StartDate = Fixture.Today().AddDays(6),
                EndDate = Fixture.Today().AddDays(10)
            };

            var subject = CreateSubject(nextOpenPeriod);

            var result = await subject.For(Fixture.Today());
            Assert.False(result.isValid);
            Assert.True(result.isWarningOnly);
            Assert.Equal(KnownErrors.ItemPostedToDifferentPeriod, result.code);
        }

        [Fact]
        public async Task ShouldThrowErrorIfCurrentPeriodIsClosedAndNextPeriodNotFound()
        {
            var subject = CreateSubject();

            var result = await subject.For(Fixture.Today());
            Assert.False(result.isValid);
            Assert.False(result.isWarningOnly);
            Assert.Equal(KnownErrors.CouldNotDeterminePostPeriod, result.code);
        }
    }
}