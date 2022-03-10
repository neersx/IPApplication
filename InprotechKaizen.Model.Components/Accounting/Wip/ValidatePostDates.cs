using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IValidatePostDates
    {
        Task<(bool isValid, bool isWarningOnly, string code)> For(DateTime entryDate, SystemIdentifier module = SystemIdentifier.TimeAndBilling);

        Task<IEnumerable<OpenPeriod>> GetOpenPeriodsFor(SystemIdentifier module = SystemIdentifier.TimeAndBilling, DateTime? periodsBefore = null);

        Task<OpenPeriod> GetMinOpenPeriodFor(DateTime itemDate, SystemIdentifier module = SystemIdentifier.TimeAndBilling);
    }

    public class ValidatePostDates : IValidatePostDates
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _today;

        public ValidatePostDates(IDbContext dbContext, Func<DateTime> today)
        {
            _dbContext = dbContext;
            _today = today;
        }

        public async Task<IEnumerable<OpenPeriod>> GetOpenPeriodsFor(SystemIdentifier module = SystemIdentifier.TimeAndBilling, DateTime? periodsBefore = null)
        {
            return await (from p in _dbContext.Set<Period>()
                          where (p.ClosedForModules == null || (p.ClosedForModules & module) != module)
                                && (periodsBefore != null && p.StartDate < periodsBefore || periodsBefore == null)
                          select new OpenPeriod
                          {
                              StartDate = p.StartDate,
                              EndDate = p.EndDate,
                              PostingCommenced = p.PostingCommenced
                          }).ToArrayAsync();
        }

        public async Task<OpenPeriod> GetMinOpenPeriodFor(DateTime itemDate, SystemIdentifier module = SystemIdentifier.TimeAndBilling)
        {
            var currentPeriodId = await (from p in _dbContext.Set<Period>()
                                where p.StartDate <= itemDate && p.EndDate >= itemDate
                                    select p.Id).FirstOrDefaultAsync();

            return await (from p in _dbContext.Set<Period>()
                          where (p.ClosedForModules == null || (p.ClosedForModules & module) != module) && p.Id > currentPeriodId
                          orderby p.Id
                          select new OpenPeriod
                          {
                              StartDate = p.StartDate,
                              EndDate = p.EndDate,
                              PostingCommenced = p.PostingCommenced
                          }).FirstOrDefaultAsync();
        }

        public async Task<(bool isValid, bool isWarningOnly, string code)> For(DateTime entryDate, SystemIdentifier module = SystemIdentifier.TimeAndBilling)
        {
            var dateToValidate = entryDate.Date;

            var openPeriods = await (from p in _dbContext.Set<Period>()
                                     where p.ClosedForModules == null || (p.ClosedForModules & module) != module
                                     select p).ToListAsync();

            if (!openPeriods.Any())
            {
                return (false, false, KnownErrors.CouldNotDeterminePostPeriod);
            }

            var validPeriod = openPeriods.Where(_ => _.PostingCommenced != null && _.PostingCommenced < dateToValidate)
                                         .OrderByDescending(_ => _.PostingCommenced)
                                         .FirstOrDefault();

            if (validPeriod != null && dateToValidate <= validPeriod.EndDate)
            {
                if (dateToValidate <= _today().Date)
                {
                    return (true, false, string.Empty);
                }

                return (false, false, KnownErrors.CannotPostFutureDate);
            }

            var transactionPeriod = openPeriods.FirstOrDefault(_ => _.StartDate <= dateToValidate && _.EndDate >= dateToValidate);
            if (transactionPeriod != null)
            {
                if (dateToValidate <= _today().Date)
                {
                    return (true, false, string.Empty);
                }

                return (false, false, KnownErrors.CannotPostFutureDate);
            }

            var closedTransactionPeriod = _dbContext.Set<Period>().FirstOrDefault(_ => _.StartDate <= dateToValidate && _.EndDate >= dateToValidate);
            if (closedTransactionPeriod == null)
            {
                return (false, false, KnownErrors.CouldNotDeterminePostPeriod);
            }

            var nextOpenPeriod = openPeriods.Where(_ => _.Id > closedTransactionPeriod.Id).OrderBy(_ => _.Id).FirstOrDefault();
            if (nextOpenPeriod == null)
            {
                return (false, false, KnownErrors.CouldNotDeterminePostPeriod);
            }

            return (false, true, KnownErrors.ItemPostedToDifferentPeriod);
        }
    }

    public class OpenPeriod
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public DateTime? PostingCommenced { get; set; }
    }
}