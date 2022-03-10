using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public class BestNarrative
    {
        public short Key { get; set; }

        /// <summary>
        ///     NarrativeTitle
        /// </summary>
        public string Value { get; set; }

        /// <summary>
        ///     NarrativeText
        /// </summary>
        public string Text { get; set; }
    }

    public interface IBestNarrativeResolver
    {
        Task<BestNarrative> Resolve(string requestedCulture, string activityKey, int? staffNameId, int? caseId = null, int? debtorId = null);
    }

    public class BestNarrativeResolver : IBestNarrativeResolver
    {
        readonly IDbContext _dbContext;
        
        public BestNarrativeResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<BestNarrative> Resolve(string requestedCulture, string activityKey, int? staffNameId, int? caseId = null, int? debtorId = null)
        {
            if (caseId.HasValue)
            {
                var caseInfo = _dbContext.Set<Case>().Single(_ => _.Id == caseId);

                var debtor = await (from cn in _dbContext.Set<CaseName>()
                                    where cn.CaseId == caseId && cn.NameTypeId == KnownNameTypes.Debtor && (debtorId == null || cn.NameId == debtorId)
                                    orderby cn.Sequence
                                    select cn.NameId)
                    .FirstOrDefaultAsync();

                var typeOfMark = caseInfo.TypeOfMark?.Id;

                var treatAsLocal = await (from ta in _dbContext.Set<TableAttributes>()
                                          where ta.TableCodeId == 5002 &&
                                                ta.ParentTable == "COUNTRY" &&
                                                ta.SourceTableId == (short) TableTypes.CountryAttribute
                                          select ta.GenericKey)
                    .AnyAsync(_ => _ == caseInfo.CountryId);

                var narrativeBestFit = from nr in _dbContext.Set<NarrativeRule>()
                                          where nr.WipCode == activityKey &&
                                                (nr.DebtorId == null || debtor == nr.DebtorId.Value) &&
                                                (nr.StaffId == null || nr.StaffId == staffNameId) &&
                                                (nr.CaseTypeId == null || nr.CaseTypeId == caseInfo.TypeId) &&
                                                (nr.CountryCode == null || nr.CountryCode == caseInfo.CountryId) &&
                                                (nr.PropertyTypeId == null || nr.PropertyTypeId == caseInfo.PropertyTypeId) &&
                                                (nr.CaseCategoryId == null || nr.CaseCategoryId == caseInfo.CategoryId) &&
                                                (nr.SubTypeId == null || nr.SubTypeId == caseInfo.SubTypeId) &&
                                                (nr.TypeOfMark == null || nr.TypeOfMark == typeOfMark) &&
                                                (nr.IsLocalCountry == null || nr.IsLocalCountry == treatAsLocal) &&
                                                (nr.IsForeignCountry == null || nr.IsForeignCountry == !treatAsLocal)
                                          select new RankedNarrativeRule
                                          {
                                              NarrativeId = nr.NarrativeId,
                                              NarrativeRuleId = nr.NarrativeRuleId,
                                              CaseTypeId = nr.CaseTypeId,
                                              CountryCode = nr.CountryCode,
                                              PropertyTypeId = nr.PropertyTypeId,
                                              CaseCategoryId = nr.CaseCategoryId,
                                              SubTypeId = nr.SubTypeId,
                                              TypeOfMark = nr.TypeOfMark,
                                              DebtorId = nr.DebtorId,
                                              StaffId = nr.StaffId,
                                              IsLocalCountry = nr.IsLocalCountry,
                                              IsForeignCountry = nr.IsForeignCountry,
                                              BestFitScore = (nr.DebtorId == null ? "0" : "1") +
                                                             (nr.StaffId == null ? "0" : "1") +
                                                             (nr.CaseTypeId == null ? "0" : "1") +
                                                             (nr.CountryCode == null ? "0" : "1") +
                                                             (nr.IsLocalCountry == null ? "0" : "1") +
                                                             (nr.IsForeignCountry == null ? "0" : "1") +
                                                             (nr.PropertyTypeId == null ? "0" : "1") +
                                                             (nr.CaseCategoryId == null ? "0" : "1") +
                                                             (nr.SubTypeId == null ? "0" : "1") +
                                                             (nr.TypeOfMark == null ? "0" : "1") +
                                                             nr.NarrativeRuleId
                                          };

                var list = await (from n in _dbContext.Set<Narrative>()
                                  join nr in narrativeBestFit on n.NarrativeId equals nr.NarrativeId
                                  where nr.NarrativeRuleId.ToString() == nr.BestFitScore.Substring(10)
                                        && nr.BestFitScore.Substring(0, 10) == narrativeBestFit.Max(_ => _.BestFitScore.Substring(0, 10))
                                  select new BestNarrative
                                  {
                                      Key = n.NarrativeId,
                                      Value = DbFuncs.GetTranslation(n.NarrativeTitle, null, n.NarrativeTitleTid, requestedCulture),
                                      Text = DbFuncs.GetTranslation(n.NarrativeText, null, n.NarrativeTextTid, requestedCulture)
                                  })
                    .ToArrayAsync();

                return list.Length != 1 ? null : list.Single();
            }

            var matches = from nr in _dbContext.Set<NarrativeRule>()
                          where nr.WipCode == activityKey &&
                                (nr.DebtorId == null || nr.DebtorId == debtorId) &&
                                (nr.StaffId == null || nr.StaffId == staffNameId) &&
                                nr.CaseTypeId == null &&
                                nr.CountryCode == null &&
                                nr.PropertyTypeId == null &&
                                nr.CaseCategoryId == null &&
                                nr.SubTypeId == null &&
                                nr.TypeOfMark == null &&
                                nr.IsLocalCountry == null &&
                                nr.IsForeignCountry == null
                          select new RankedNarrativeRule
                          {
                              NarrativeId = nr.NarrativeId,
                              NarrativeRuleId = nr.NarrativeRuleId,
                              CaseTypeId = nr.CaseTypeId,
                              CountryCode = nr.CountryCode,
                              PropertyTypeId = nr.PropertyTypeId,
                              CaseCategoryId = nr.CaseCategoryId,
                              SubTypeId = nr.SubTypeId,
                              TypeOfMark = nr.TypeOfMark,
                              DebtorId = nr.DebtorId,
                              StaffId = nr.StaffId,
                              IsLocalCountry = nr.IsLocalCountry,
                              IsForeignCountry = nr.IsForeignCountry,
                              BestFitScore = (nr.DebtorId == null ? "0" : "1") +
                                             (nr.StaffId == null ? "0" : "1") +
                                             (nr.CaseTypeId == null ? "0" : "1") +
                                             (nr.CountryCode == null ? "0" : "1") +
                                             (nr.IsLocalCountry == null ? "0" : "1") +
                                             (nr.IsForeignCountry == null ? "0" : "1") +
                                             (nr.PropertyTypeId == null ? "0" : "1") +
                                             (nr.CaseCategoryId == null ? "0" : "1") +
                                             (nr.SubTypeId == null ? "0" : "1") +
                                             (nr.TypeOfMark == null ? "0" : "1") +
                                             nr.NarrativeRuleId
                          };

            var narratives = await (from n in _dbContext.Set<Narrative>()
                                    join nr in matches on n.NarrativeId equals nr.NarrativeId
                                    where nr.NarrativeRuleId.ToString() == nr.BestFitScore.Substring(10)
                                          && nr.BestFitScore.Substring(0, 10) == matches.Max(_ => _.BestFitScore.Substring(0, 10))
                                    select new BestNarrative
                                    {
                                        Key = n.NarrativeId,
                                        Value = DbFuncs.GetTranslation(n.NarrativeTitle, null, n.NarrativeTitleTid, requestedCulture),
                                        Text = DbFuncs.GetTranslation(n.NarrativeText, null, n.NarrativeTextTid, requestedCulture)
                                    })
                .ToArrayAsync();

            return narratives.Length != 1 ? null : narratives.Single();
        }
    }
}