using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IBillSettingsResolver
    {
        Task<BillSettings> Resolve(int debtorId, int? caseId, string action, int? entityId);
    }

    public class BillSettingsResolver : IBillSettingsResolver
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public BillSettingsResolver(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<BillSettings> Resolve(int debtorId, int? caseId, string action, int? entityId)
        {
            var debtor = await GetDebtorDetail(debtorId);

            var @case = await GetCaseDetail(caseId, action);

            var billingEntityId = await GetBillingEntity(debtorId, caseId, @case.Action, entityId, debtor, @case);

            var minimumWipReasonCode = _siteControlReader.Read<string>(SiteControls.MinimumWIPReason);

            var interim = await (from br in _dbContext.GetBillRuleRows(null, null, caseId, debtorId, billingEntityId,
                                                                       debtor.NameCategoryId, debtor.IsLocalClient,
                                                                       @case.CaseTypeId, @case.PropertyTypeId, @case.Action, @case.CountryId)
                                 orderby br.RuleType, br.BestFitScore descending
                                 select new InterimBillRule
                                 {
                                     BillingEntityId = br.BillingEntity,
                                     MinimumNetBill = br.MinimumNetBill,
                                     WipCode = br.WipCode
                                 }).ToArrayAsync();

            return new BillSettings
            {
                DefaultEntityId = interim.Where(_ => _.BillingEntityId != null).FirstOrDefault()?.BillingEntityId,
                MinimumNetBill = interim.Where(_ => string.IsNullOrWhiteSpace(_.WipCode) && _.MinimumNetBill != null).FirstOrDefault()?.MinimumNetBill,
                MinimumWipValues = interim.Where(_ => !string.IsNullOrWhiteSpace(_.WipCode) && _.MinimumNetBill != null).Select(_ => new MinimumWipValue
                {
                    MinValue = _.MinimumNetBill ?? 0,
                    WipCode = _.WipCode
                }),
                MinimumWipReasonCode = minimumWipReasonCode
            };
        }

        async Task<int?> GetBillingEntity(int debtorId, int? caseId, string action, int? entityId, (int? NameCategoryId, bool IsLocalClient) debtor, InterimCaseDetail @case)
        {
            if (entityId != null) return entityId;
            return await (from br in _dbContext.GetBillRuleRows(BillRuleType.BillingEntity, null, caseId, debtorId, null,
                                                                debtor.NameCategoryId, debtor.IsLocalClient,
                                                                @case.CaseTypeId, @case.PropertyTypeId, action, @case.CountryId)
                          orderby br.BestFitScore descending
                          select br.BillingEntity).FirstOrDefaultAsync();
        }

        async Task<(int? NameCategoryId, bool IsLocalClient)> GetDebtorDetail(int debtorId)
        {
            var clientDetail = await _dbContext.Set<ClientDetail>().SingleAsync(_ => _.Id == debtorId);

            return (clientDetail.NameCategoryId, clientDetail.LocalClientFlag == 1);
        }

        async Task<InterimCaseDetail> GetCaseDetail(int? caseId, string action)
        {
            if (caseId != null && string.IsNullOrWhiteSpace(action))
            {
                action = await (from oa in _dbContext.Set<OpenAction>()
                                where oa.CaseId == caseId
                                orderby oa.PoliceEvents descending, oa.DateUpdated descending
                                select oa.ActionId).FirstOrDefaultAsync();
            }

            var defaultCaseDetail = new InterimCaseDetail {Action = action};

            return caseId != null
                ? await (from c in _dbContext.Set<Case>()
                         where c.Id == caseId
                         select new InterimCaseDetail
                         {
                             Action = action,
                             PropertyTypeId = c.PropertyTypeId,
                             CountryId = c.CountryId,
                             CaseTypeId = c.TypeId
                         }).FirstOrDefaultAsync() ?? defaultCaseDetail
                : defaultCaseDetail;
        }

        class InterimBillRule
        {
            public int? BillingEntityId { get; set; }

            public decimal? MinimumNetBill { get; set; }

            public string WipCode { get; set; }
        }

        class InterimCaseDetail
        {
            public string CaseTypeId { get; set; }
            public string CountryId { get; set; }
            public string PropertyTypeId { get; set; }
            public string Action { get; set; }
        }
    }

    public class BillSettings
    {
        public int? DefaultEntityId { get; set; }
        public decimal? MinimumNetBill { get; set; }
        public IEnumerable<MinimumWipValue> MinimumWipValues { get; set; } = new List<MinimumWipValue>();
        public string MinimumWipReasonCode { get; set; }
    }

    public class MinimumWipValue
    {
        public string WipCode { get; set; }
        public decimal MinValue { get; set; }
    }
}