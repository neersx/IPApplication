using System;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.BulkBilling;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IValidateTransactionDates
    {
        Task<(bool isValid, bool isWarningOnly, string code)> For(DateTime? itemDate);
    }

    public class ValidateTransactionDates : IValidateTransactionDates
    {
        readonly IBillDateSettingsResolver _billDateSettingsResolver;
        readonly IBillingSiteSettingsResolver _billingSiteSettingsResolver;
        readonly Func<DateTime> _now;
        readonly IValidatePostDates _validatePostDates;

        public ValidateTransactionDates(IValidatePostDates validatePostDates,
                                        IBillingSiteSettingsResolver billingSiteSettingsResolver,
                                        IBillDateSettingsResolver billDateSettingsResolver,
                                        Func<DateTime> now)
        {
            _validatePostDates = validatePostDates;
            _billingSiteSettingsResolver = billingSiteSettingsResolver;
            _billDateSettingsResolver = billDateSettingsResolver;
            _now = now;
        }

        public async Task<(bool isValid, bool isWarningOnly, string code)> For(DateTime? itemDate)
        {
            // converted from acw_ValidateTransactionDate
            var onlySupportedModule = SystemIdentifier.TimeAndBilling;

            if (itemDate == null)
            {
                return (false, false, KnownErrors.ItemDateNotProvided);
            }

            var today = _now().Date;

            var billingSiteSettings = await _billingSiteSettingsResolver.Resolve(new BillingSiteSettingsScope {Scope = SettingsResolverScope.WithoutUserSpecificSettings});

            if (itemDate.Value.Date < today && billingSiteSettings.BillDateRestriction != BillDateRestriction.PastAndFutureBillDatesWithinCurrentOpenPeriodAllowed)
            {
                return (false, false, KnownErrors.BillDatesInThePastNotAllowed);
            }

            var allOpenPeriods = (await _validatePostDates.GetOpenPeriodsFor(onlySupportedModule)).ToArray();
            var currentPeriod = (from p in allOpenPeriods
                                 where p.StartDate <= today && p.EndDate >= today
                                 select p).SingleOrDefault();
            
            var endDate = currentPeriod?.EndDate.Date;
            var commenceDate = currentPeriod?.PostingCommenced?.Date;

            if (billingSiteSettings.BillDateRestriction == BillDateRestriction.OnlyFutureBillDateWithinCurrentOpenPeriodAllowed &&
                (itemDate.Value.Date > endDate || itemDate.Value.Date > today && commenceDate == null))
            {
                return (false, false, KnownErrors.CannotPostFutureDate);
            }

            if (billingSiteSettings.BillDateRestriction == BillDateRestriction.OnlyFutureBillDateWithinSamePeriodAsTodayAllowed &&
                itemDate.Value.Date > endDate)
            {
                return (false, false, KnownErrors.FutureBillDatesAllowedIfDateWithinCurrentPeriod);
            }

            var postPeriod = (from p in allOpenPeriods
                              where p.StartDate <= itemDate && p.EndDate >= itemDate
                              select p).SingleOrDefault();

            if (billingSiteSettings.BillDateRestriction == BillDateRestriction.OnlyFutureBillDateWithinAnyOpenPeriodAllowed &&
                itemDate.Value.Date > today && postPeriod == null)
            {
                return (false, false, KnownErrors.ItemDateCannotBeInFuturePeriodThatIsClosedForModule);
            }

            if (billingSiteSettings.BillDateForwardOnly)
            {
                var mostRecentlyFinalisedBillDate = (await _billDateSettingsResolver.Resolve()).LastFinalisedDate;
                if (mostRecentlyFinalisedBillDate != null && mostRecentlyFinalisedBillDate.Value.Date > itemDate.Value)
                {
                    return (false, false, KnownErrors.ItemDateEarlierThanLastFinalisedItemDate);
                }
            }

            if (postPeriod == null && currentPeriod == null)
            {
                var minPostPeriod = await _validatePostDates.GetMinOpenPeriodFor(itemDate.Value.Date, onlySupportedModule);
                return minPostPeriod == null ? (false, false, KnownErrors.CouldNotDeterminePostPeriod) 
                    : (false, true, KnownErrors.ItemPostedToDifferentPeriod);
            }

            return (true, false, null);
        }
    }
}