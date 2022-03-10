using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BulkBilling
{
    public interface IBillDateSettingsResolver
    {
        Task<BillDateSetting> Resolve();
    }

    public class BillDateSettingsResolver : IBillDateSettingsResolver
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public BillDateSettingsResolver(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<BillDateSetting> Resolve()
        {
            return new()
            {
                LastFinalisedDate = await GetMostRecentFinalisedDate(),
                ShouldChangeBillDateIfNotToday = _siteControlReader.Read<bool>(SiteControls.BillDateChange)
            };
        }

        async Task<DateTime?> GetMostRecentFinalisedDate()
        {
            if (!_siteControlReader.Read<bool>(SiteControls.BillDatesForwardOnly))
                return null;

            var typesForBillingModule = Enum.GetValues(typeof(ItemTypesForBilling)).Cast<ItemType>();

            var mostRecentDate = await (from dt in _dbContext.Set<OpenItem>()
                                        where dt.Status == TransactionStatus.Active && typesForBillingModule.Contains(dt.TypeId) && dt.ItemDate != null
                                        orderby dt.ItemDate descending
                                        select dt.ItemDate).FirstOrDefaultAsync();

            return mostRecentDate?.Date;
        }
    }

    public class BillDateSetting
    {
        public DateTime? LastFinalisedDate { get; set; }

        public bool ShouldChangeBillDateIfNotToday { get; set; }
    }
}