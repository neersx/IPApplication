using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Accounting.Time
{
    public interface ICaseSummaryNamesProvider
    {
        Task<IEnumerable<CaseSummaryName>> GetNames(int caseId);
    }

    public class CaseSummaryNamesProvider : ICaseSummaryNamesProvider
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly INameAuthorization _nameAuthorization;

        readonly string[] _summaryNameTypes =
        {
            KnownNameTypes.Instructor,
            KnownNameTypes.Debtor,
            KnownNameTypes.Owner,
            KnownNameTypes.StaffMember,
            KnownNameTypes.Signatory
        };

        public CaseSummaryNamesProvider(IDbContext dbContext,
                                        IPreferredCultureResolver preferredCultureResolver,
                                        INameAuthorization nameAuthorization)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _nameAuthorization = nameAuthorization;
        }

        public async Task<IEnumerable<CaseSummaryName>> GetNames(int caseId)
        {
            var culture = _preferredCultureResolver.Resolve();

            var interim = await GetNames(caseId, culture).ToArrayAsync();

            var nameIds = interim.Select(_ => _.Id).Distinct().ToArray();
            var accessibleNameIds = (await _nameAuthorization.AccessibleNames(nameIds)).ToArray();

            var names = (from n in await _dbContext.Set<Name>()
                                                  .Where(_ => nameIds.Contains(_.Id))
                                                  .Select(_ => new
                                                  {
                                                      Name = _
                                                  })
                                                  .ToArrayAsync()
                         select new
                         {
                             n.Name.Id,
                             n.Name.NameCode,
                             FormattedName = n.Name.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)
                         }).ToDictionary(k => k.Id, v => v);

            return from i in interim
                   let canViewName = accessibleNameIds.Contains(i.Id)
                   select new CaseSummaryName
                   {
                       Id = i.Id,
                       Type = i.Type,
                       TypeId = i.TypeId,
                       Name = names[i.Id].FormattedName,
                       Reference = i.Reference,
                       NameCode = i.NameCode,
                       NameAndCode = i.ShowNameCode.Format(names[i.Id].FormattedName, names[i.Id].NameCode),
                       ShowNameCodeRestriction = i.ShowNameCodeRestriction,
                       BillingPercentage = i.BillingPercentage,
                       CanView = canViewName
                   };
        }

        IQueryable<CaseSummaryName> GetNames(int caseId, string culture)
        {
            var filteredNameTypes = from nt in _dbContext.Set<NameType>()
                                    where _summaryNameTypes.Contains(nt.NameTypeCode)
                                    select nt;

            var caseNames = from cn in _dbContext.Set<CaseName>()
                            join n in _dbContext.Set<Name>() on cn.NameId equals n.Id into nJ
                            from n in nJ
                            join nt in filteredNameTypes on cn.NameTypeId equals nt.NameTypeCode into nt1
                            from nt in nt1
                            where cn.CaseId == caseId
                            select new CaseSummaryName
                            {
                                Id = cn.NameId,
                                Type = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, culture),
                                TypeId = nt.NameTypeCode,
                                Reference = cn.Reference,
                                NameCode = n.NameCode,
                                ShowNameCodeRaw = (decimal)(nt.ShowNameCode == null ? 0 : nt.ShowNameCode),
                                SequenceNo = cn.Sequence,
                                ShowNameCodeRestriction = nt.IsNameRestricted == 1,
                                BillingPercentage = cn.BillingPercentage
                            };

            return from n in caseNames
                   orderby n.Type
                   select n;
        }
    }

    public class CaseSummaryName
    {
        public bool ShowNameCodeRestriction { get; set; }
        public int Id { get; set; }
        public string Type { get; set; }
        public string TypeId { get; set; }
        public string Reference { get; set; }
        public string Name { get; set; }
        public string NameCode { get; set; }
        public string NameAndCode { get; set; }
        [JsonIgnore]
        public decimal ShowNameCodeRaw { get; set; }
        [JsonIgnore]
        public ShowNameCode ShowNameCode => (ShowNameCode)Convert.ToInt32(ShowNameCodeRaw);
        public int SequenceNo { get; set; }
        public decimal? BillingPercentage { get; set; }
        public bool ShowBillPercentage => BillingPercentage.GetValueOrDefault() > 0 && BillingPercentage.GetValueOrDefault() < 100;
        public bool CanView { get; set; }
    }
}