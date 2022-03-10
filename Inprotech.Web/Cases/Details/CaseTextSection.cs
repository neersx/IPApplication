using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseTextSection
    {
        Task<IEnumerable<CaseTextData>> Retrieve(int caseKey, params string[] textTypeKeys);
        Task<CaseHistoryDataModel> GetHistoryData(int caseKey, string textTypeKey, string textClass, int? languageKey);
        Task<IEnumerable<CaseTextData>> GetClassAndText(int caseKey, string classKey = null);
    }

    public class CaseTextSection : ICaseTextSection
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControl;

        public CaseTextSection(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, ISiteControlReader siteControl)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControl = siteControl;
        }

        public async Task<IEnumerable<CaseTextData>> Retrieve(int caseKey, params string[] textTypeKeys)
        {
            var culture = _preferredCultureResolver.Resolve();
            var userId = _securityContext.User.Id;
            var historySiteControl = _siteControl.Read<bool?>(SiteControls.KEEPSPECIHISTORY);
            var userIsExternal = _securityContext.User.IsExternalUser;

            var texts = from ct in _dbContext.Set<CaseText>()
                        join tt in _dbContext.FilterUserTextTypes(userId, culture, userIsExternal, false) on ct.Type equals tt.TextType
                        join tc in _dbContext.Set<TableCode>() on ct.Language equals tc.Id into tc1
                        from tc in tc1.DefaultIfEmpty()
                        where ct.Class == null && ct.CaseId == caseKey
                        select new InterimText
                        {
                            TextNo = ct.Number ?? 0,
                            TextType = ct.Type,
                            TextTypeDescription = tt.TextDescription,
                            Notes = ct.IsLongText == 1
                                ? DbFuncs.GetTranslation(null, ct.LongText, ct.LongTextTId, culture)
                                : DbFuncs.GetTranslation(ct.ShortText, null, ct.ShortTextTId, culture),
                            LanguageKey = ct.Language,
                            Language = tc == null ? null : DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture),
                            ModifiedDate = ct.ModifiedDate,
                            TextClass = ct.Class
                        };

            if (textTypeKeys.Any())
            {
                texts = from i in texts where textTypeKeys.Contains(i.TextType) select i;
            }

            var interim = await texts.ToArrayAsync();

            var mostRecent = from ct in interim
                             group ct by new {ct.TextType, ct.Language}
                             into g1
                             select new
                             {
                                 Count = g1.Count(),
                                 Max = g1.Max(_ => _.Score),
                                 g1.Key
                             };

            return from ct in interim
                   join m in mostRecent on new {ct.TextType, ct.Language, ct.Score} equals new {m.Key.TextType, m.Key.Language, Score = m.Max}
                   orderby ct.TextTypeDescription, ct.Language
                   select new CaseTextData
                   {
                       Type = ct.TextTypeDescription,
                       TypeKey = ct.TextType,
                       Language = ct.Language,
                       LanguageKey = ct.LanguageKey,
                       Notes = ct.Notes,
                       HasHistory = (historySiteControl ?? true) && m.Count > 1,
                       TextClass = ct.TextClass
                   };
        }

        public async Task<CaseHistoryDataModel> GetHistoryData(int caseKey, string textTypeKey, string textClass, int? languageKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            var historySiteControl = _siteControl.Read<bool?>(SiteControls.KEEPSPECIHISTORY);

            var userId = _securityContext.User.Id;

            var userIsExternal = _securityContext.User.IsExternalUser;

            var caseTextData = await (from c in _dbContext.Set<Case>()
                                      join ct in _dbContext.Set<CaseText>() on c.Id equals ct.CaseId
                                      join tt in _dbContext.FilterUserTextTypes(userId, culture, userIsExternal, false) on ct.Type equals tt.TextType
                                      join tc in _dbContext.Set<TableCode>() on ct.Language equals tc.Id into tc1
                                      from tc in tc1.DefaultIfEmpty()
                                      where c.Id == caseKey && ct.Type.Equals(textTypeKey) && ct.Language == languageKey && ct.Class == textClass
                                      select new CaseHistoryDataModel
                                      {
                                          Irn = c.Irn,
                                          TextClass = textClass,
                                          TextDescription = tt.TextDescription,
                                          Type = ct.Type,
                                          Language = tc == null ? null : DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture)
                                      }).FirstAsync();

            var textHistoryData = await (from ct in _dbContext.Set<CaseText>()
                                         where ct.CaseId == caseKey && ct.Type.Equals(caseTextData.Type) &&
                                               ct.Language == languageKey && ct.Class == textClass
                                               && (ct.ModifiedDate != null || (ct.ShortText ?? ct.LongText) != null)
                                         orderby ct.ModifiedDate descending
                                         select new CaseHistoryModel
                                         {
                                             DateModified = ct.ModifiedDate,
                                             Text = ct.LongText ?? ct.ShortText
                                         }).ToArrayAsync();

            if (textHistoryData.Length > 1 && (historySiteControl ?? true))
            {
                caseTextData.History = textHistoryData;
            }

            return caseTextData;
        }

        public async Task<IEnumerable<CaseTextData>> GetClassAndText(int caseKey, string classKey = null)
        {
            var userId = _securityContext.User.Id;
            var userIsExternal = _securityContext.User.IsExternalUser;
            var culture = _preferredCultureResolver.Resolve();

            var caseText = _dbContext.Set<CaseText>().Where(_ => _.CaseId == caseKey && _.Type == KnownTextTypes.GoodsServices);
            if (!string.IsNullOrEmpty(classKey))
                caseText = caseText.Where(_ => _.Class.Equals(classKey));

            var texts = from ct in caseText
                        join tt in _dbContext.FilterUserTextTypes(userId, culture, userIsExternal, false) on ct.Type equals tt.TextType
                        join tc in _dbContext.Set<TableCode>() on ct.Language equals tc.Id into tc1
                        from tc in tc1.DefaultIfEmpty()
                        select new InterimText
                        {
                            TextNo = ct.Number ?? 0,
                            Notes = ct.IsLongText == 1
                                ? DbFuncs.GetTranslation(null, ct.LongText, ct.LongTextTId, culture)
                                : DbFuncs.GetTranslation(ct.ShortText, null, ct.ShortTextTId, culture),
                            Language = tc == null ? null : DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture),
                            ModifiedDate = ct.ModifiedDate,
                            TextClass = ct.Class
                        };

            var interim = await texts.ToArrayAsync();

            var mostRecent = from ct in interim
                             group ct by new {ct.TextClass, ct.Language}
                             into g1
                             select new
                             {
                                 Count = g1.Count(),
                                 Max = g1.Max(_ => _.Score),
                                 g1.Key
                             };

            return (from ct in interim
                    join m in mostRecent on new {ct.TextClass, ct.Language, ct.Score} equals new {m.Key.TextClass, m.Key.Language, Score = m.Max}
                    select new CaseTextData
                    {
                        Language = ct.Language,
                        LanguageKey = ct.LanguageKey,
                        Notes = ct.Notes,
                        TextClass = ct.TextClass
                    })
                   .OrderBy(_ => _.TextClass).ThenBy(_ => _.Language);
        }

        class InterimText
        {
            public short TextNo { get; set; }

            public string Notes { get; set; }

            public string TextType { get; set; }

            public string TextTypeDescription { get; set; }

            public DateTime? ModifiedDate { get; set; }

            public string Language { get; set; }

            public string Score => $"{(ModifiedDate.HasValue ? ModifiedDate.Value.ToString("O") : string.Empty)}{TextNo}";
            
            public string TextClass { get; set; }

            public int? LanguageKey { get; set; }
        }
    }

    public class CaseTextData
    {
        public string Type { get; set; }
        public string TypeKey { get; set; }

        public string Language { get; set; }

        public string Notes { get; set; }

        public bool HasHistory { get; set; }

        public string TextClass { get; set; }

        public int? LanguageKey { get; set; }
    }

    public class CaseHistoryModel
    {
        public DateTime? DateModified { get; set; }
        public string Text { get; set; }
    }

    public class CaseHistoryDataModel
    {
        public string Irn { get; set; }
        public string TextClass { get; set; }
        public string TextDescription { get; set; }
        public string Language { get; set; }
        public string Type { get; set; }
        public string TypeKey { get; set; }
        public IEnumerable<CaseHistoryModel> History { get; set; }
    }
}