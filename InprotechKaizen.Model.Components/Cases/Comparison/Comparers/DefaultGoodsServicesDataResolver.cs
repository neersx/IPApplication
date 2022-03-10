using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class DefaultGoodsServicesDataResolver : IGoodsServicesDataResolver
    {
        readonly IDbContext _dbContext;
        readonly IClassStringComparer _classStringComparer;
        readonly IBackgroundProcessLogger<GoodsServicesComparer> _logger;
        readonly IUseDateComparer _useDateComparer;
        readonly IHtmlAsPlainText _htmlAsPlainText;

        public DefaultGoodsServicesDataResolver(IDbContext dbContext, 
                                                IUseDateComparer useDateComparer,
                                                IClassStringComparer classStringComparer,
                                                IBackgroundProcessLogger<GoodsServicesComparer> logger,
                                                IHtmlAsPlainText htmlAsPlainText)
        {
            _dbContext = dbContext;
            _htmlAsPlainText = htmlAsPlainText;
            _classStringComparer = classStringComparer;
            _useDateComparer = useDateComparer;
            _logger = logger;
        }

        public IEnumerable<Results.GoodsServices> Resolve(IEnumerable<CaseText> goodsServices,
                                                          IEnumerable<ComparisonScenario<Models.GoodsServices>> comparisonScenarios,
                                                          int? caseId = null,
                                                          string defaultLanguage = null)
        {
            if(caseId == null)
                throw new ArgumentNullException(nameof(caseId));

            var caseTexts = goodsServices.ToArray();
            SetFirstUseData(caseId.Value, caseTexts);

            var result = new List<Results.GoodsServices>();

            var importedGoodsServices = comparisonScenarios.Select(_ => _.Mapped).ToList();

            foreach (var gs in caseTexts)
            {
                var imported = importedGoodsServices.SingleOrDefault(a =>
                                                                         _classStringComparer.Equals(a.Class, gs.Class)) ??
                               new Models.GoodsServices();

                var inpro = gs.FirstUse ?? new ClassFirstUse(gs.CaseId, "NullAccess");

                var item = new Results.GoodsServices
                {
                    TextType = gs.Type,
                    TextNo = gs.Number,
                    Class = new Value<string>
                    {
                        OurValue = gs.Class,
                        TheirValue = imported.Class
                    },
                    FirstUsedDate = _useDateComparer.Compare(
                                                             inpro.FirstUsedDate, imported.FirstUsedDate),

                    FirstUsedDateInCommerce = _useDateComparer.Compare(
                                                                       inpro.FirstUsedInCommerceDate, imported.FirstUsedDateInCommerce),
                    Text = new Value<string>
                    {
                        OurValue = _htmlAsPlainText.Retrieve(gs.Text),
                        TheirValue = imported.Text
                    }
                };

                if (item.FirstUsedDate.HasParseError() || item.FirstUsedDateInCommerce.HasParseError())
                {
                    _logger.Warning("Error parsing FirstUseDate / FirstUseDateInCommerce during GoodsServicesComparer.", JsonConvert.SerializeObject(new
                    {
                        CaseId = caseId,
                        item
                    }));
                }

                if (importedGoodsServices.Contains(imported))
                {
                    importedGoodsServices.Remove(imported);
                }

                item.Text.Different = !string.Equals(item.Text.OurValue, item.Text.TheirValue);
                item.Text.Updateable = (bool) item.Text.Different && !string.IsNullOrEmpty(item.Text.TheirValue);

                item.Class.Different = !_classStringComparer.Equals(item.Class.OurValue, item.Class.TheirValue);
                item.Class.Updateable = item.Text.Different.GetValueOrDefault() && !string.IsNullOrEmpty(item.Class.TheirValue);

                result.Add(item);
            }

            result.AddRange(
                            importedGoodsServices.Select(_ =>
                                                             new Results.GoodsServices
                                                             {
                                                                 Class = new Value<string>
                                                                 {
                                                                     TheirValue = _.Class,
                                                                     Updateable = true,
                                                                     Different = true
                                                                 },
                                                                 FirstUsedDate = _useDateComparer.Compare(null, _.FirstUsedDate),
                                                                 FirstUsedDateInCommerce = _useDateComparer.Compare(null, _.FirstUsedDateInCommerce),
                                                                 Text = new Value<string>
                                                                 {
                                                                     TheirValue = _.Text,
                                                                     Updateable = true,
                                                                     Different = true
                                                                 }
                                                             }));

            return result.OrderBy(o => o.Class.OurValue, new NumericComparer())
                         .ThenBy(o => o.Class.TheirValue, new NumericComparer());
        }

        void SetFirstUseData(int caseId, CaseText[] goodsAndServices)
        {
            var classes = goodsAndServices.Select(a => a.Class).Distinct().ToArray();
            var firstUses = _dbContext.Set<ClassFirstUse>()
                                      .Where(a => a.CaseId == caseId && classes.Contains(a.Class));

            if (!firstUses.Any())
            {
                return;
            }

            foreach (var gs in goodsAndServices) gs.FirstUse = firstUses.SingleOrDefault(a => a.CaseId == gs.CaseId && a.Class == gs.Class);
        }
    }
}