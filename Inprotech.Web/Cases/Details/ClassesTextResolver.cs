using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    public interface IClassesTextResolver
    {
        dynamic Resolve(string @class, int caseId);
    }

    public class ClassesTextResolver : IClassesTextResolver
    {
        readonly ILanguageResolver _languageResolver;
        readonly ISiteControlReader _siteControlReader;
        readonly IDbContext _dbContext;

        public ClassesTextResolver(ILanguageResolver languageResolver, ISiteControlReader siteControlReader, IDbContext dbContext)
        {
            _languageResolver = languageResolver;
            _siteControlReader = siteControlReader;
            _dbContext = dbContext;
        }

        public dynamic Resolve(string @class, int caseId)
        {
            var defaultLanguage = _languageResolver.Resolve() ?? _siteControlReader.Read<int?>(SiteControls.LANGUAGE);

            if (!defaultLanguage.HasValue)
            {
                var caseTexts = CaseTexts(caseId, @class);

                if (caseTexts.Any())
                    return new {GsText = GsText(caseTexts), HasMultipleLanguageClassText = HasMultipleCaseText(caseId, @class)};
            }
            else
            {
                var caseTexts = CaseTexts(caseId, @class, defaultLanguage);

                if (caseTexts.Any())
                    return new {GsText = GsText(caseTexts), HasMultipleLanguageClassText = HasMultipleCaseText(caseId, @class, defaultLanguage)};

                caseTexts = CaseTexts(caseId, @class);

                if (caseTexts.Any())
                    return new {GsText = GsText(caseTexts), HasMultipleLanguageClassText = HasMultipleCaseText(caseId, @class)};
            }

            return new {GsText = string.Empty, HasMultipleLanguageClassText = HasMultipleCaseText(caseId, @class)};
        }

        IQueryable<CaseText> CaseTexts(int caseId, string @class, int? language = null)
        {
            return _dbContext.Set<CaseText>()
                             .Where(_ => _.Type == KnownTextTypes.GoodsServices
                                         && _.CaseId == caseId
                                         && _.Class.Equals(@class)
                                         && _.Language == language);
        }

        bool HasMultipleCaseText(int caseId, string @class, int? language = null)
        {
            return _dbContext.Set<CaseText>().Any(_ => _.Type == KnownTextTypes.GoodsServices
                                                       && _.CaseId == caseId
                                                       && _.Class.Equals(@class)
                                                       && _.Language != language);
        }

        string GsText(IQueryable<CaseText> caseTexts)
        {
            var relevantRecord = caseTexts.OrderByDescending(ct => ct.Number).First();
            return relevantRecord.IsLongText == 1m ? relevantRecord.LongText : relevantRecord.ShortText;
        }
    }
}
