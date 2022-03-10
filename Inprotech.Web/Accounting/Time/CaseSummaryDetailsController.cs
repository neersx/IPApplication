using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting")]
    public class CaseSummaryDetailsController : ApiController
    {
        readonly ICaseSummaryNamesProvider _caseSummaryNamesProvider;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ICaseStatusReader _statusReader;
        readonly ISubjectSecurityProvider _subjectSecurity;
        readonly IAccountingProvider _accountingProvider;
        readonly ISiteControlReader _siteControlReader;
        readonly Func<DateTime> _now;

        public CaseSummaryDetailsController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                                            ICaseStatusReader statusReader, ICaseSummaryNamesProvider caseSummaryNamesProvider,
                                            ISubjectSecurityProvider subjectSecurity, IAccountingProvider accountingProvider, ISiteControlReader siteControlReader, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _statusReader = statusReader;
            _caseSummaryNamesProvider = caseSummaryNamesProvider;
            _subjectSecurity = subjectSecurity;
            _accountingProvider = accountingProvider;
            _siteControlReader = siteControlReader;
            _now = now;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("time/{caseKey:int}/summary")]
        public async Task<dynamic> GetCaseSummary(int caseKey)
        {
            var @case = await _dbContext.Set<Case>()
                                        .SingleOrDefaultAsync(v => v.Id == caseKey);

            if (@case == null) return new HttpResponseMessage(HttpStatusCode.NotFound);

            var culture = _preferredCultureResolver.Resolve();
            var names = (await _caseSummaryNamesProvider.GetNames(caseKey)).ToArray();
            return new
            {
                CaseKey = @case.Id,
                @case.Irn,
                Title = DbFuncs.GetTranslation(@case.Title, null, @case.TitleTId, culture),
                CaseStatus = _statusReader.GetCaseStatusDescription(@case.CaseStatus),
                RenewalStatus = _statusReader.GetCaseStatusDescription(@case.Property?.RenewalStatus),
                OfficialNumber = @case.CurrentOfficialNumber,
                Instructor = names.SingleOrDefault(n => n.TypeId == KnownNameTypes.Instructor),
                Debtors = names.Where(n => n.TypeId == KnownNameTypes.Debtor).OrderBy(_ => _.SequenceNo),
                Owners = names.Where(n => n.TypeId == KnownNameTypes.Owner).OrderBy(_ => _.SequenceNo),
                StaffMember = names.Where(n => n.TypeId == KnownNameTypes.StaffMember).OrderBy(_ => _.SequenceNo),
                Signatory = names.Where(n => n.TypeId == KnownNameTypes.Signatory).OrderBy(_ => _.SequenceNo),
                ActiveBudget = @case.BudgetRevisedAmt ?? @case.BudgetAmount,
                CaseNarrativeText = _siteControlReader.Read<bool>(SiteControls.TimesheetShowCaseNarrative) ? GetCaseNarrativeText(@case) : null,
                EnableRichText = _siteControlReader.Read<bool>(SiteControls.EnableRichTextFormatting)
            };
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("time/{caseKey:int}/financials")]
        public async Task<CaseBillingSummary> GetBillingDetails(int caseKey)
        {
            var today = _now().Date;
            var accessToWip = _subjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems);
            var accessToBillingHistory = _subjectSecurity.HasAccessToSubject(ApplicationSubject.BillingHistory);
            
            TotalWork workPerformed;
            decimal? activeBudget = 0;
            if (!accessToWip)
            {
                return new CaseBillingSummary
                {
                    UnpostedTime = 0,
                    Wip = 0,
                    TotalWorkPerformed = 0,
                    TotalWorkForPeriod = 0,
                    ActiveBudget = 0,
                    LastInvoiceDate = accessToBillingHistory ? await _accountingProvider.GetLastInvoiceDate(caseKey) : null
                };
            }
            
            var caseBudget = _dbContext.Set<Case>()
                                       .Where(v => v.Id == caseKey)
                                       .Select(_ => new
                                       {
                                           Revised = _.BudgetRevisedAmt,
                                           Original = _.BudgetAmount,
                                           Start = _.BudgetStartDate,
                                           End = _.BudgetEndDate
                                       }).SingleOrDefault();
            if (caseBudget == null)
            {
                workPerformed = await GetWorkHistory(caseKey);
                return new CaseBillingSummary
                {
                    UnpostedTime = await GetUnpostedValue(caseKey),
                    Wip = await _accountingProvider.UnbilledWipFor(caseKey),
                    TotalWorkPerformed = workPerformed != null ? workPerformed.TotalWorkPerformed : 0,
                    TotalWorkForPeriod = workPerformed != null ? workPerformed.TotalWorkForPeriod : 0,
                    ActiveBudget = activeBudget,
                    LastInvoiceDate = accessToBillingHistory ? await _accountingProvider.GetLastInvoiceDate(caseKey) : null
                };
            }

            workPerformed = await GetWorkHistory(caseKey, caseBudget.Start, caseBudget.End);
            if ((caseBudget.Start == null || today >= caseBudget.Start) && (caseBudget.End == null || today <= caseBudget.End))
            {
                activeBudget = caseBudget.Revised ?? caseBudget.Original;
            }

            return new CaseBillingSummary
            {
                UnpostedTime = await GetUnpostedValue(caseKey),
                Wip = await _accountingProvider.UnbilledWipFor(caseKey),
                TotalWorkPerformed = workPerformed != null ? workPerformed.TotalWorkPerformed : 0,
                TotalWorkForPeriod = workPerformed != null ? workPerformed.TotalWorkForPeriod : 0,
                ActiveBudget = activeBudget,
                LastInvoiceDate = accessToBillingHistory ? await _accountingProvider.GetLastInvoiceDate(caseKey) : null
            };
        }

        async Task<decimal?> GetUnpostedValue(int caseKey)
        {
            var unpostedList = await (from d in _dbContext.Set<Diary>()
                                      where d.CaseId == caseKey
                                            && !d.WipEntityId.HasValue
                                            && !d.TransactionId.HasValue
                                            && d.IsTimer == 0
                                            && d.TimeValue.HasValue
                                      select d.TimeValue).ToArrayAsync();

            if (unpostedList.Any())
            {
                return unpostedList.Select(_ => _.GetValueOrDefault())
                                   .Aggregate((total, item) => total + item);
            }

            return 0;
        }

        string GetCaseNarrativeText(Case @case)
        {
            var text = @case.CaseTexts.Where(_ => _.TextType.Id == KnownTextTypes.Billing && _.Language == null)
                            .OrderByDescending(_ => _.Number).FirstOrDefault()
                            ?.Text;
            return text;
        }

        async Task<dynamic> GetWorkHistory(int caseKey, DateTime? budgetStart = null, DateTime? budgetEnd = null)
        {
            var allowedMovements = new[]
            {
                (short) MovementClass.Entered,
                (short) MovementClass.AdjustUp,
                (short) MovementClass.AdjustDown
            };

            var workHistoryList = await (from h in _dbContext.Set<WorkHistory>()
                                         where h.CaseId == caseKey
                                               && h.Status != (int) TransactionStatus.Draft
                                               && h.MovementClass != null && allowedMovements.Contains((short) h.MovementClass)
                                         select new { h.LocalValue, h.TransDate}).ToArrayAsync();
            decimal totalWork = 0;
            decimal totalWorkForPeriod = 0;
            if (workHistoryList.Any())
            {
                totalWork = workHistoryList.Select(_ => _.LocalValue ?? 0)
                                      .Aggregate((total, item) => total + item);

                totalWorkForPeriod = workHistoryList
                                    .Where(_ => (budgetStart == null || _.TransDate >= budgetStart) && (budgetEnd == null || _.TransDate <= budgetEnd))
                                    .Select(_ => _.LocalValue ?? 0).Aggregate((total, item) => total + item);
            }

            return new TotalWork { TotalWorkPerformed = totalWork, TotalWorkForPeriod = totalWorkForPeriod};
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/agedWipBalances")]
        public async Task<dynamic> GetWipBalances(int caseKey)
        {
            if (!_subjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems)) return null;

            var brackets = await _accountingProvider.GetAgeingBrackets();
            return await _accountingProvider.GetAgedWipTotals(caseKey, brackets.BaseDate, brackets.Current, brackets.Previous, brackets.Last);
        }

        class TotalWork
        {
            public decimal? TotalWorkPerformed { get; set; }
            public decimal? TotalWorkForPeriod { get; set; }
        }
    }

    public class CaseBillingSummary
    {
        public decimal? UnpostedTime { get; set; }
        public decimal? Wip { get; set; }
        public decimal? TotalWorkPerformed { get; set; }
        public decimal? ActiveBudget { get; set; }

        public decimal? BudgetUsed
        {
            get
            {
                if (ActiveBudget.HasValue && ActiveBudget > 0)
                    return Math.Round(TotalWorkForPeriod.GetValueOrDefault() / ActiveBudget.GetValueOrDefault() * 100, MidpointRounding.AwayFromZero);

                return null;
            }
        }

        public DateTime? LastInvoiceDate { get; set; }
        public decimal? TotalWorkForPeriod { get; set; }
    }
}