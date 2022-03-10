using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Tax;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public interface IDraftWipAdditionalDetailsResolver
    {
        Task<DraftWipAdditionalDetailsResolver.DraftWipDetails> Resolve(int userIdentityId, string culture,
                                                                        int debtorId,
                                                                        int? caseId,
                                                                        string billCurrency, DateTime billDate,
                                                                        int? staffId, int? entityId, DateTime? itemDate,
                                                                        string wipTypeId, string wipCategory, string wipCode);
    }

    public class DraftWipAdditionalDetailsResolver : IDraftWipAdditionalDetailsResolver
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IExchangeDetailsResolver _exchangeDetailsResolver;
        readonly IDefaultTaxCodeResolver _defaultTaxCodeResolver;
        readonly ITaxRateResolver _taxRateResolver;

        StaffDetails _staffDetails;

        public DraftWipAdditionalDetailsResolver(IDbContext dbContext,
                                                 ISiteControlReader siteControlReader,
                                                 IExchangeDetailsResolver exchangeDetailsResolver,
                                                 IDefaultTaxCodeResolver defaultTaxCodeResolver,
                                                 ITaxRateResolver taxRateResolver)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _exchangeDetailsResolver = exchangeDetailsResolver;
            _defaultTaxCodeResolver = defaultTaxCodeResolver;
            _taxRateResolver = taxRateResolver;
        }

        public async Task<DraftWipDetails> Resolve(int userIdentityId, string culture,
                                                   int debtorId,
                                                   int? caseId,
                                                   string billCurrency, DateTime billDate,
                                                   int? staffId, int? entityId, DateTime? itemDate,
                                                   string wipTypeId, string wipCategory, string wipCode)
        {
            if (wipCode == null) throw new ArgumentNullException(nameof(wipCode));

            var staffDetails = await GetStaffDetails(userIdentityId, culture, staffId);

            var exchangeRateDetails = await _exchangeDetailsResolver.Resolve(userIdentityId, billCurrency, wipCategory, wipTypeId, billDate, caseId, debtorId);

            var wipDetails = await GetWipDetails(culture, wipCode);

            var taxCode = await _defaultTaxCodeResolver.Resolve(userIdentityId, culture, debtorId, caseId, wipCode, staffId, entityId);

            var taxRate = string.IsNullOrWhiteSpace(taxCode)
                ? null
                : (await _taxRateResolver.Resolve(userIdentityId, culture, taxCode, staffId, entityId, itemDate))?.Rate;

            return new DraftWipDetails
            {
                StaffSignOffName = staffDetails?.StaffSignOffName,
                ProfitCentre = staffDetails?.ProfitCentre,
                ProfitCentreCode = staffDetails?.ProfitCentreCode,
                BillBuyRate = exchangeRateDetails?.BuyRate ?? 0,
                BillSellRate = exchangeRateDetails?.SellRate ?? 0,
                TaxCode = taxCode,
                TaxRate = taxRate ?? 0,
                WipCodeSortOrder = wipDetails?.WipCodeSortOrder ?? 0,
                WipTypeDescription = wipDetails?.WipTypeDescription,
                WipCategoryDescription = wipDetails?.WipCategoryDescription,
                WipTypeSortOrder = wipDetails?.WipTypeSortOrder ?? 0,
                WipCategorySortOrder = wipDetails?.WipCategorySortOrder ?? 0
            };
        }

        async Task<dynamic> GetWipDetails(string culture, string wipCode)
        {
            return await (from w in _dbContext.Set<WipTemplate>()
                          join wt in _dbContext.Set<WipType>() on w.WipTypeId equals wt.Id
                          join wc in _dbContext.Set<WipCategory>() on wt.CategoryId equals wc.Id
                          where w.WipCode == wipCode
                          select new
                          {
                              WipCodeSortOrder = w.WipCodeSortOrder ?? 0,
                              WipTypeSortOrder = wt.WipTypeSortOrder ?? 0,
                              WipCategorySortOrder = wc.CategorySortOrder ?? 0,
                              WipTypeDescription = DbFuncs.GetTranslation(wt.Description, null, wt.DescriptionTid, culture),
                              WipCategoryDescription = DbFuncs.GetTranslation(wc.Description, null, wc.DescriptionTid, culture)
                          }).SingleOrDefaultAsync();
        }

        async Task<StaffDetails> GetStaffDetails(int userIdentityId, string culture, int? staffId)
        {
            async Task<StaffDetails> GetProfitCentreFromStaffWhoRecordedTheWip()
            {
                return await (from e in _dbContext.Set<Employee>()
                              join p in _dbContext.Set<ProfitCentre>() on e.ProfitCentre equals p.Id into p1
                              from p in p1.DefaultIfEmpty()
                              where e.Id == staffId
                              select new StaffDetails
                              {
                                  StaffSignOffName = e.SignOffName,
                                  ProfitCentreCode = e.ProfitCentre,
                                  ProfitCentre = DbFuncs.GetTranslation(p.Name, null, p.NameTId, culture)
                              }).SingleOrDefaultAsync();
            }

            async Task<StaffDetails> GetProfitCentreFromSignedInUser()
            {
                return await (from e in _dbContext.Set<Employee>()
                              join p in _dbContext.Set<ProfitCentre>() on e.ProfitCentre equals p.Id into p1
                              from p in p1.DefaultIfEmpty()
                              join u in _dbContext.Set<User>() on new { Id = (int?)e.Id } equals new { Id = staffId == null ? u.NameId : staffId } into u1
                              from u in u1.DefaultIfEmpty()
                              where u.Id == userIdentityId
                              select new StaffDetails
                              {
                                  StaffSignOffName = e.SignOffName,
                                  ProfitCentreCode = e.ProfitCentre,
                                  ProfitCentre = DbFuncs.GetTranslation(p.Name, null, p.NameTId, culture)
                              }).SingleOrDefaultAsync();
            }

            return _staffDetails ??= _siteControlReader.Read<int?>(SiteControls.WIPProfitCentreSource)
                switch
                {
                    1 => await GetProfitCentreFromSignedInUser(),
                    _ => await GetProfitCentreFromStaffWhoRecordedTheWip()
                };
        }

        public class StaffDetails
        {
            public string StaffSignOffName { get; set; }
            public string ProfitCentreCode { get; set; }
            public string ProfitCentre { get; set; }
        }

        public class DraftWipDetails : StaffDetails
        {
            public string TaxCode { get; set; }
            public decimal TaxRate { get; set; }
            public decimal BillBuyRate { get; set; }
            public decimal BillSellRate { get; set; }
            public int WipCodeSortOrder { get; set; }
            public int WipTypeSortOrder { get; set; }
            public int WipCategorySortOrder { get; set; }
            public string WipTypeDescription { get; set; }
            public string WipCategoryDescription { get; set; }
        }
    }
}