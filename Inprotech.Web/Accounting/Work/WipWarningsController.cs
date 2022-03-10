using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Accounting.Work
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting/warnings")]
    public class WipWarningsController : ApiController
    {
        readonly IPreferredCultureResolver _culture;
        readonly IDbContext _dbContext;
        readonly INameCreditLimitCheck _nameCreditLimitCheck;
        readonly Func<DateTime> _now;
        readonly IBudgetWarnings _budgetCheck;
        readonly IPrepaymentWarningCheck _prepaymentCheck;
        readonly IBillingCapCheck _billinCapCheck;
        readonly IWipStatusEvaluator _statusEvaluator;
        readonly ISiteControlReader _sitecontrolReader;

        public WipWarningsController(IDbContext dbContext, IPreferredCultureResolver culture, INameCreditLimitCheck nameCreditLimitCheck, Func<DateTime> now, IBudgetWarnings budgetCheck, IPrepaymentWarningCheck prepaymentCheck, IBillingCapCheck billinCapCheck, IWipStatusEvaluator statusEvaluator, ISiteControlReader sitecontrolReader)
        {
            _dbContext = dbContext;
            _culture = culture;
            _nameCreditLimitCheck = nameCreditLimitCheck;
            _now = now;
            _budgetCheck = budgetCheck;
            _prepaymentCheck = prepaymentCheck;
            _billinCapCheck = billinCapCheck;
            _statusEvaluator = statusEvaluator;
            _sitecontrolReader = sitecontrolReader;
        }

        [HttpGet]
        [Route("name/{nameId:int}")]
        [RequiresNameAuthorization]
        public async Task<dynamic> GetWipWarningsForName(int nameId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                         TimeQuery q)
        {
            var culture = _culture.Resolve();
            var restriction = await _dbContext.Set<ClientDetail>().Where(_ => _.Id == nameId && _.DebtorStatus != null).SingleOrDefaultAsync();
            var creditLimitCheck = await _nameCreditLimitCheck.For(nameId);
            var prepaymentCheckResult = await _prepaymentCheck.ForName(nameId);
            var billingCapCheckResult = await _billinCapCheck.ForName(nameId, q.SelectedDate);
            return (creditLimitCheck == null || !creditLimitCheck.Exceeded) &&
                   (restriction?.DebtorStatus == null ||
                    restriction?.DebtorStatus?.RestrictionAction == KnownDebtorRestrictions.NoRestriction) &&
                   (prepaymentCheckResult == null || !prepaymentCheckResult.Exceeded) && billingCapCheckResult == null
                ? null
                : new
                {
                    Restriction = new RestrictableName
                    {
                        NameId = nameId,
                        BadDebtor = restriction?.DebtorStatus,
                        DebtorStatus = DbFuncs.GetTranslation(restriction?.DebtorStatus.Status, null, restriction?.DebtorStatus.StatusTId, culture),
                        EnforceNameRestriction = true
                    },
                    CreditLimitCheckResult = creditLimitCheck,
                    PrepaymentCheckResult = prepaymentCheckResult,
                    BillingCapCheckResult = billingCapCheckResult
                };
        }

        [HttpGet]
        [Route("case/{caseId:int}")]
        [RequiresCaseAuthorization]
        public async Task<WipWarningData> GetWipWarningsForCase(int caseId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                                TimeQuery q)
        {
            var culture = _culture.Resolve();
            var now = _now();
            var restrictedNames = await (from cn in _dbContext.Set<CaseName>()
                                         join n in _dbContext.Set<Name>() on cn.NameId equals n.Id
                                         join nt in _dbContext.Set<NameType>() on cn.NameType equals nt
                                         join cl in _dbContext.Set<ClientDetail>() on cn.NameId equals cl.Id
                                         where cn.CaseId == caseId && (cn.StartingDate == null || cn.StartingDate <= now.Date) &&
                                               (cn.ExpiryDate == null || cn.ExpiryDate > now.Date)
                                         select new RestrictableName
                                         {
                                             DebtorName = n,
                                             NameTypeData = nt,
                                             NameType = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, culture),
                                             BadDebtor = cl.DebtorStatus,
                                             DebtorStatus = DbFuncs.GetTranslation(cl.DebtorStatus.Status, null, cl.DebtorStatus.StatusTId, culture),
                                             EnforceNameRestriction = nt.IsNameRestricted != null && nt.IsNameRestricted == 1m
                                         }).ToArrayAsync();

            var result = restrictedNames.Select(_ => new CaseWipWarnings
            {
                CaseName = _,
                CreditLimitCheckResult = null
            }).ToArray();

            foreach (var res in result.Where(_ => _.CaseName.NameTypeData.NameTypeCode == KnownNameTypes.Debtor))
            {
                res.CreditLimitCheckResult = await _nameCreditLimitCheck.For(res.CaseName.Id.GetValueOrDefault());
            }

            return new WipWarningData
            {
                CaseWipWarnings = result.Where(_ => _.CaseName.BadDebtor is {RestrictionAction: < KnownDebtorRestrictions.NoRestriction} || _.CreditLimitCheckResult != null && _.CreditLimitCheckResult.Exceeded),
                BudgetCheckResult = await _budgetCheck.For(caseId, q.SelectedDate),
                PrepaymentCheckResult = await _prepaymentCheck.ForCase(caseId),
                BillingCapCheckResult = await _billinCapCheck.ForCase(caseId, q.SelectedDate),
                RestrictOnWip = _sitecontrolReader.Read<bool>(SiteControls.RestrictOnWIP)
            };
        }

        [HttpPost]
        [Route("validate")]
        public async Task<bool> ValidateConfirmationPassword([FromBody] JObject confirmationData)
        {
            var input = confirmationData.ToObject<ConfirmationData>();
            var result = await _dbContext.Set<ClientDetail>()
                                         .Where(_ => _.Id == input.NameId && _.DebtorStatus != null && _.DebtorStatus.ClearTextPassword == input.ClearTextPassword)
                                         .SingleOrDefaultAsync();
            return result != null;
        }

        [HttpGet]
        [Route("editableStatus/{entryNo}/{staffId}")]
        public async Task<WipStatusEnum> CheckIfEditable(int entryNo, int staffId)
        {
            return await _statusEvaluator.GetWipStatus(entryNo, staffId);
        }
    }

    internal class ConfirmationData
    {
        public int NameId { get; set; }
        public string ClearTextPassword { get; set; }
    }

    public class WipWarningData
    {
        public dynamic BudgetCheckResult { get; set; }
        public IEnumerable<CaseWipWarnings> CaseWipWarnings { get; set; }
        public dynamic PrepaymentCheckResult { get; set; }
        public dynamic BillingCapCheckResult { get; set; }
        public bool RestrictOnWip { get; set; }
    }

    public class CaseWipWarnings
    {
        public RestrictableName CaseName { get; set; }
        public dynamic CreditLimitCheckResult { get; set; }
    }

    public class RestrictableName
    {
        [JsonIgnore]
        public Name DebtorName { get; set; }

        [JsonIgnore]
        public NameType NameTypeData { get; set; }

        public string DebtorStatus { get; set; }

        public int? Id => DebtorName?.Id;
        public string DisplayName => DebtorName?.Formatted();
        public string NameType { get; set; }
        public int? DebtorStatusActionFlag => (int?) BadDebtor?.RestrictionType;
        public bool RequirePassword => DebtorStatusActionFlag == KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation;
        public bool Blocked => DebtorStatusActionFlag == KnownDebtorRestrictions.DisplayError;
        public bool EnforceNameRestriction { get; set; }

        [JsonIgnore]
        public DebtorStatus BadDebtor { get; set; }

        public int? NameId { get; set; }

        public string Severity
        {
            get
            {
                switch (BadDebtor?.RestrictionType)
                {
                    case KnownDebtorRestrictions.DisplayWarning:
                    case KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation:
                        return "warning";
                    case KnownDebtorRestrictions.DisplayError:
                        return "error";
                    default:
                        return "info";
                }
            }
        }
    }

    public class TimeQuery
    {
        public DateTime SelectedDate { get; set; }
    }
}