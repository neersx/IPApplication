using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class InnographyGoodsServicesDataResolver : IGoodsServicesDataResolver
    {
        public const string EnglishLanguageCode = "en";
        readonly IDbContext _dbContext;
        readonly IClassStringComparer _classStringComparer;
        readonly IHtmlAsPlainText _htmlAsPlainText;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public InnographyGoodsServicesDataResolver(IDbContext dbContext, IClassStringComparer classStringComparer, 
                                                   IHtmlAsPlainText htmlAsPlainText, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _htmlAsPlainText = htmlAsPlainText;
            _classStringComparer = classStringComparer;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<Results.GoodsServices> Resolve(IEnumerable<CaseText> goodsServices,
                                                          IEnumerable<ComparisonScenario<Models.GoodsServices>> comparisonScenarios,
                                                          int? caseId = null,
                                                          string defaultLanguage = null)
        {
            var result = new List<Results.GoodsServices>();

            var importedGoodsServices = comparisonScenarios.Select(_ => _.Mapped).ToList();

            defaultLanguage = string.IsNullOrWhiteSpace(defaultLanguage) ? EnglishLanguageCode : defaultLanguage;

            var goodsServicesByClass = goodsServices.ToArray().GroupBy(_ => _.Class);

            var availableLanguages = Languages().ToArray();

            foreach (var gs in goodsServicesByClass)
            {
                var imported = importedGoodsServices.FirstOrDefault(a =>
                                                                         _classStringComparer.Equals(a.Class, gs.Key)
                                                                         && a.LanguageCode == defaultLanguage) ??
                               importedGoodsServices.FirstOrDefault(a =>
                                                                         _classStringComparer.Equals(a.Class, gs.Key)) ??
                               new Models.GoodsServices();

                LanguagePicklistItem selectedLanguage = null;
                
                if(imported.LanguageCode != null)
                    selectedLanguage = availableLanguages.FirstOrDefault(_ => _.Code == imported.LanguageCode);

                var goodsServicesText = gs.FirstOrDefault(_ => _.Language == selectedLanguage?.Key);
                var defaultGoodsServicesText = gs.First();

                var item = new Results.GoodsServices
                {
                    TextType = defaultGoodsServicesText.Type,
                    TextNo = goodsServicesText?.Number,
                    Class = new Value<string>
                    {
                        OurValue = defaultGoodsServicesText.Class,
                        TheirValue = imported.Class
                    },
                    Language = new Value<LanguagePicklistItem>
                    {
                        OurValue = new LanguagePicklistItem
                        {
                            Code = selectedLanguage?.Code,
                            Key = selectedLanguage?.Key,
                            Value = selectedLanguage?.Value
                        },
                        TheirValue = new LanguagePicklistItem
                        {
                            Code = selectedLanguage?.Code,
                            Key = selectedLanguage?.Key,
                            Value = selectedLanguage?.Value
                        }
                    },
                    Text = new Value<string>
                    {
                        OurValue = _htmlAsPlainText.Retrieve(goodsServicesText?.Text),
                        TheirValue = imported.Text
                    },
                    MultipleImportedLanguage = importedGoodsServices.Count(a => _classStringComparer.Equals(a.Class, gs.Key)) > 1
                };

                if (importedGoodsServices.Contains(imported))
                {
                    importedGoodsServices.RemoveAll(_ => _classStringComparer.Equals(_.Class, gs.Key));
                }

                item.Text.Different = !string.Equals(item.Text.OurValue, item.Text.TheirValue);
                item.Text.Updateable = (bool) item.Text.Different && !string.IsNullOrEmpty(item.Text.TheirValue);

                item.Class.Different = !_classStringComparer.Equals(item.Class.OurValue, item.Class.TheirValue);
                item.Class.Updateable = item.Text.Different.GetValueOrDefault() && !string.IsNullOrEmpty(item.Class.TheirValue);

                result.Add(item);
            }

            var remainingGoodsServices = importedGoodsServices.GroupBy(_ => _.Class);

            result.AddRange(from rgs in remainingGoodsServices
                            let imported =
                                rgs.FirstOrDefault(a => a.LanguageCode == defaultLanguage) ??
                                rgs.First()
                            let selectedLanguage = imported.LanguageCode == null ? null : availableLanguages.FirstOrDefault(_ => _.Code == imported.LanguageCode)
                            select new Results.GoodsServices
                            {
                                Class = new Value<string>
                                {
                                    TheirValue = imported.Class, 
                                    Updateable = true, 
                                    Different = true
                                },
                                Language = new Value<LanguagePicklistItem>
                                {
                                    TheirValue = new LanguagePicklistItem
                                    {
                                        Code = selectedLanguage?.Code, 
                                        Key = selectedLanguage?.Key,
                                        Value = selectedLanguage?.Value
                                    },
                                    OurValue = new LanguagePicklistItem
                                    {
                                        Code = selectedLanguage?.Code, 
                                        Key = selectedLanguage?.Key,
                                        Value = selectedLanguage?.Value
                                    }
                                },
                                Text = new Value<string>
                                {
                                    TheirValue = imported.Text, 
                                    Updateable = true, 
                                    Different = true
                                },
                                MultipleImportedLanguage = rgs.Count() > 1
                            });

            return result.OrderBy(o => o.Class.OurValue, new NumericComparer())
                         .ThenBy(o => o.Class.TheirValue, new NumericComparer());
        }

        IEnumerable<LanguagePicklistItem> Languages()
        {
            var culture = _preferredCultureResolver.Resolve();
            var availableLanguages = from ct in _dbContext.Set<TableCode>()
                                     where ct.TableTypeId == (int) TableTypes.Language
                                     select new LanguagePicklistItem
                                     {
                                         Code = ct.UserCode,
                                         Key = ct.Id,
                                         Value = DbFuncs.GetTranslation(ct.Name, null, ct.NameTId, culture)
                                     };

            return availableLanguages;
        }
    }
}