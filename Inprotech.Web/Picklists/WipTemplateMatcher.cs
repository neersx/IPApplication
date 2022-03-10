using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using WipCategory = InprotechKaizen.Model.Accounting.WipCategory;

namespace Inprotech.Web.Picklists
{
    public interface IWipTemplateMatcher
    {
        Task<IEnumerable<WipTemplatePicklistItem>> Get(string search, bool isTimesheetActivity = true, int? caseId = null, bool onlyDisbursements = false);
    }

    public class WipTemplateMatcher : IWipTemplateMatcher
    {
        readonly IPreferredCultureResolver _cultureResolver;
        readonly IDbContext _dbContext;

        public WipTemplateMatcher(IDbContext dbContext, IPreferredCultureResolver cultureResolver)
        {
            _dbContext = dbContext;
            _cultureResolver = cultureResolver;
        }

        public async Task<IEnumerable<WipTemplatePicklistItem>> Get(string search, bool isTimesheetActivity = true, int? caseId = null, bool onlyDisbursements = false)
        {
            var culture = _cultureResolver.Resolve();
            var wipTypes = _dbContext.Set<WipType>();

            var initialItems = from wx in _dbContext.Set<WipTemplate>().Where(wx => !wx.IsNotInUse)
                           join wy in wipTypes on wx.WipType equals wy into wipTypesDetails
                           from wyD in wipTypesDetails.DefaultIfEmpty()
                           select new WipTemplatePicklistItem
                           {
                               Key = wx.WipCode,
                               Value = DbFuncs.GetTranslation(wx.Description, null, wx.DescriptionTid, culture),
                               TypeId = wx.WipTypeId,
                               Type = wyD != null ? DbFuncs.GetTranslation(wyD.Description, null, wyD.DescriptionTid, culture) : string.Empty,
                               CaseTypeId = wx.CaseTypeId,
                               PropertyTypeId = wx.PropertyTypeId,
                               CountryCode = wx.CountryCode,
                               ActionId = wx.ActionId,
                               UsedBy = wx.UsedBy,
                               WipTypeCategoryId = wyD.Category.Id
                           };
            if (isTimesheetActivity)
            {
                initialItems = initialItems.Where(_ => (_.UsedBy & (short) KnownApplicationUsage.Timesheet) == (short) KnownApplicationUsage.Timesheet && _.WipTypeCategoryId == WipCategory.ServiceCharge && _.Type != string.Empty);
            }

            if (onlyDisbursements)
            {
                initialItems = initialItems.Where(_ => _.WipTypeCategoryId == WipCategory.Disbursements && _.Type != string.Empty);
            }

            var caseInfo = from c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>().Where(_ => _.Id == caseId)
                           join a in _dbContext.Set<OpenAction>() on c.Id equals a.CaseId into ca
                           from caseWithAction in ca.DefaultIfEmpty()
                           select new
                           {
                               c.TypeId,
                               c.PropertyTypeId,
                               c.CountryId,
                               ActionId = caseWithAction != null ? caseWithAction.ActionId : null,
                               PoliceEvents = caseWithAction != null ? caseWithAction.PoliceEvents ?? 0 : 0
                           };

            var items = caseId.HasValue
                ? (from item in initialItems
                   from ca in caseInfo
                   where (item.CaseTypeId == ca.TypeId || item.CaseTypeId == null)
                         && (item.PropertyTypeId == ca.PropertyTypeId || item.PropertyTypeId == null)
                         && (item.CountryCode == ca.CountryId || item.CountryCode == null)
                         && (ca.PoliceEvents == 1 && item.ActionId == ca.ActionId || item.ActionId == null)
                   select item).Distinct()
                : (from item in initialItems
                   select item);

            if (!string.IsNullOrEmpty(search))
            {
                items = items.Where(_ => _.Value.Contains(search) || _.Key.StartsWith(search));
            }

            return await items.OrderBy(_ => _.Value).ToArrayAsync();
        }
    }
}