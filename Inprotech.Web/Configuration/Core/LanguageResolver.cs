using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    public interface ILanguageResolver
    {
        int? Resolve();
    }

    public class LanguageResolver : ILanguageResolver
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDbContext _dbContext;

        public LanguageResolver(IDbContext dbContext,
            IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            
        }

        public int? Resolve()
        {
            var culture = _preferredCultureResolver.Resolve().ToUpper();

            var language = GetLanguage(culture) ?? GetLanguage(GetParentCulture(culture));
            
            return language?.Id;
        }

        TableCode GetLanguage(string culture)
        {
            return _dbContext.Set<TableCode>().FirstOrDefault(_ => _.TableTypeId == (int) TableTypes.Language && _.UserCode.ToUpper().Equals(culture));
        }

        string GetParentCulture(string culture)
        {
            switch (culture)
            {
                case "ZH-HK": 
                case "ZH-TW":
                    return "ZH-CHT";
                case "ZH-MO":
                case "ZH-CN":
                case "ZH-SG":
                    return "ZH-CHS";
                case "ZH-CHT": 
                case "ZH-CHS":
                    return null;
                case "NB-NO":
                case "NN-NO":
                    return "NO";
                default: 
                    if(culture.IndexOf('-') > -1)
                        return culture.Substring(0, culture.IndexOf('-'));
                    return culture;
            }
        }
    }
}
