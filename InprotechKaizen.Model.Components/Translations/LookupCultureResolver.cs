using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Translations;

namespace InprotechKaizen.Model.Components.Translations
{
    public interface ILookupCultureResolver
    {
        LookupCulture Resolve(string requestedCulture);
    }

    public class LookupCultureResolver : ILookupCultureResolver
    {
        static readonly Dictionary<string, string> Map = new Dictionary<string, string>
        {
            {"ZH-HK", "ZH-CHT"},
            {"ZH-TW", "ZH-CHT"},
            {"ZH-MO", "ZH-CHS"},
            {"ZH-CN", "ZH-CHS"},
            {"ZH-SG", "ZH-CHS"},
            {"ZH-CHT", null},
            {"ZH-CHS", null},
            {"NB-NO", "NO"},
            {"NN-NO", "NO"}
        };

        readonly IDbContext _dbContext;

        public LookupCultureResolver(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public LookupCulture Resolve(string requestedCulture)
        {
            if (TranslationNotRequiredFor(requestedCulture))
                return LookupCulture.TranslationNotRequired();

            string culture = requestedCulture.ToUpper();
            string fallbackCulture = FindFallbackCultureFor(culture);

            if (Queryable.Where<TranslatedText>(_dbContext.Set<TranslatedText>(), tt => !tt.HasSourceChanged)
                         .Any(tt => tt.CultureId == culture || tt.CultureId == (fallbackCulture ?? culture)))
                return new LookupCulture(culture, fallbackCulture ?? culture
                    );

            return LookupCulture.TranslationNotRequired();
        }

        bool TranslationNotRequiredFor(string requestedCulture)
        {
            if (requestedCulture == null) return true;            

            SiteControl dbCultureSiteControl =
                Queryable.Single<SiteControl>(_dbContext.Set<SiteControl>(), s => s.ControlId == SiteControls.DatabaseCulture);

            return
                string.Compare(dbCultureSiteControl.StringValue, requestedCulture, StringComparison.OrdinalIgnoreCase) ==
                0;
        }

        static string FindFallbackCultureFor(string requestedCulture)
        {
            string fallbackCulture;
            if (Map.TryGetValue(requestedCulture.ToUpper(), out fallbackCulture))
                return fallbackCulture;

            string[] specificCulture = requestedCulture.Split('-');
            return specificCulture.Count() == 2 ? specificCulture.First() : null;
        }
    }

    public class LookupCulture
    {
        public LookupCulture(string requested, string fallback)
        {
            Requested = requested;
            Fallback = fallback;
        }

        public LookupCulture()
        {
            NotApplicable = true;
        }

        public string Fallback { get; private set; }
        public string Requested { get; private set; }

        public bool CanFallback
        {
            get { return string.CompareOrdinal(Requested, Fallback) == 0; }
        }

        public bool NotApplicable { get; private set; }

        public static LookupCulture TranslationNotRequired()
        {
            return new LookupCulture();
        }
    }
}
