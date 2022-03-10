using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.System.Compatibility;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public interface IDiscountsAndMargins
    {
        Task<decimal?> GetBillingDiscount(int userIdentityId, string culture, int debtorId, int? caseId, decimal? billedAmount);

        Task<DiscountDetails> GetDiscountDetails(int userIdentityId, string culture, int debtorId, int? caseId = null, int? staffId = null, int? entityId = null);

        Task<MarginDetails> GetMarginDetails(int userIdentityId, string culture, int debtorId, int? caseId = null, int? staffId = null, int? entityId = null, bool? isRenewal = false);
    }

    public class DiscountsAndMargins : IDiscountsAndMargins
    {
        readonly IDbContext _dbContext;
        readonly IStoredProcedureParameterHandler _compatibleParameterHandler;

        public DiscountsAndMargins(IDbContext dbContext, IStoredProcedureParameterHandler compatibleParameterHandler)
        {
            _dbContext = dbContext;
            _compatibleParameterHandler = compatibleParameterHandler;
        }

        public async Task<decimal?> GetBillingDiscount(int userIdentityId, string culture, int debtorId, int? caseId, decimal? billedAmount)
        {
            // This procedure resets Bill Start Date as it calculates

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.CalculateNameBillingDiscountRate,
                                                                        new Parameters
                                                                        {
                                                                            { "@pnUserIdentityId", userIdentityId },
                                                                            { "@psCulture", culture },
                                                                            { "@pnCaseKey", caseId },
                                                                            { "@pnNameKey", debtorId },
                                                                            { "@pdAmountToBeBilled", billedAmount },
                                                                            { "@pdDiscount", null }
                                                                        });

            await command.ExecuteNonQueryAsync();

            return (decimal?)command.Parameters["@pdDiscount"].Value;
        }

        public async Task<DiscountDetails> GetDiscountDetails(int userIdentityId, string culture, int debtorId, int? caseId = null, int? staffId = null, int? entityId = null)
        {
            var parameters = new Parameters
            {
                { "@pnUserIdentityId", userIdentityId },
                { "@psCulture", culture },
                { "@pnCaseKey", caseId },
                { "@pnNameKey", debtorId },
                { "@pnStaffKey", staffId },
                { "@pnEntityKey", entityId }
            };

            _compatibleParameterHandler.Handle(StoredProcedures.Billing.GetDefaultDiscountDetails, parameters);

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetDefaultDiscountDetails, parameters);

            using var dr = await command.ExecuteReaderAsync();

            var discount = !await dr.ReadAsync()
                ? new DiscountDetails()
                : new DiscountDetails
                {
                    WipCode = dr.GetField<string>("WIPCode"),
                    WipDescription = dr.GetField<string>("WIPDescription"),
                    WipTypeId = dr.GetField<string>("WIPTypeId"),
                    WipCategory = dr.GetField<string>("WIPCategory"),
                    WipCategorySortOrder = dr.GetField<int>("WIPCategorySort"),
                    WipTaxCode = dr.GetField<string>("WIPTaxCode"),
                    RenewalWipCode = dr.GetField<string>("RenewalWIPCode"),
                    RenewalWipDescription = dr.GetField<string>("RenewalWIPDescription"),
                    RenewalWipTypeId = dr.GetField<string>("RenewalWIPTypeId"),
                    RenewalWipCategory = dr.GetField<string>("RenewalWIPCategory"),
                    RenewalWipCategorySortOrder = dr.GetField<int>("RenewalWIPCategorySort"),
                    RenewalWipTaxCode = dr.GetField<string>("RenewalWIPTaxCode"),
                    NarrativeId = dr.GetField<int?>("NarrativeNo"),
                    NarrativeCode = dr.GetField<string>("NarrativeCode"),
                    NarrativeTitle = dr.GetField<string>("NarrativeTitle"),
                    NarrativeText = dr.GetField<string>("NarrativeText")
                };

            if (string.IsNullOrWhiteSpace(discount.WipCode))
            {
                var w = await GetWipDetails(discount.WipCode);

                discount.WipCodeSortOrder = w.WipCodeSortOrder;
                discount.WipTypeSortOrder = w.WipTypeSortOrder;
            }

            return discount;
        }

        public async Task<MarginDetails> GetMarginDetails(int userIdentityId, string culture, int debtorId, int? caseId = null, int? staffId = null, int? entityId = null, bool? isRenewal = false)
        {
            var parameters = new Parameters
            {
                { "@pnUserIdentityId", userIdentityId },
                { "@psCulture", culture },
                { "@pnCaseKey", caseId },
                { "@pnNameKey", debtorId },
                { "@pnStaffKey", staffId },
                { "@pnEntityKey", entityId },
                { "@pbRenewalFlag", isRenewal }
            };

            _compatibleParameterHandler.Handle(StoredProcedures.Billing.GetDefaultMarginDetails, parameters);

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetDefaultMarginDetails, parameters);

            using var dr = await command.ExecuteReaderAsync();

            var margin = !await dr.ReadAsync()
                ? new MarginDetails()
                : new MarginDetails
                {
                    WipCode = dr.GetField<string>("WIPCode"),
                    WipDescription = dr.GetField<string>("WIPDescription"),
                    WipTypeId = dr.GetField<string>("WIPTypeId"),
                    WipCategory = dr.GetField<string>("WIPCategory"),
                    WipCategorySortOrder = dr.GetField<int>("WIPCategorySort"),
                    WipTaxCode = dr.GetField<string>("WIPTaxCode"),
                    NarrativeId = dr.GetField<short?>("NarrativeNo"),
                    NarrativeCode = dr.GetField<string>("NarrativeCode"),
                    NarrativeTitle = dr.GetField<string>("NarrativeTitle"),
                    NarrativeText = dr.GetField<string>("NarrativeText")
                };

            if (string.IsNullOrWhiteSpace(margin.WipCode))
            {
                var w = await GetWipDetails(margin.WipCode);

                margin.WipCodeSortOrder = w.WipCodeSortOrder;
                margin.WipTypeSortOrder = w.WipTypeSortOrder;
            }

            return margin;
        }

        async Task<dynamic> GetWipDetails(string wipCode)
        {
            return await (from w in _dbContext.Set<WipTemplate>()
                          join wt in _dbContext.Set<WipType>() on w.WipTypeId equals wt.Id
                          where w.WipCode == wipCode
                          select new
                          {
                              WipCodeSortOrder = w.WipCodeSortOrder ?? 0,
                              WipTypeSortOrder = wt.WipTypeSortOrder ?? 0
                          }).SingleAsync();
        }
    }

    public class WipDetails
    {
        public string WipCode { get; set; }
        public int WipCodeSortOrder { get; set; }
        public string WipDescription { get; set; }
        public string WipTypeId { get; set; }
        public int WipTypeSortOrder { get; set; }
        public string WipCategory { get; set; }
        public int WipCategorySortOrder { get; set; }
        public string WipTaxCode { get; set; }
        public int? NarrativeId { get; set; }
        public string NarrativeCode { get; set; }
        public string NarrativeTitle { get; set; }
        public string NarrativeText { get; set; }
    }
    
    public class DiscountDetails : WipDetails
    {
        public string RenewalWipCode { get; set; }
        public string RenewalWipDescription { get; set; }
        public string RenewalWipTypeId { get; set; }
        public string RenewalWipCategory { get; set; }
        public int RenewalWipCategorySortOrder { get; set; }
        public string RenewalWipTaxCode { get; set; }
    }

    public class MarginDetails : WipDetails
    {
    }
}
