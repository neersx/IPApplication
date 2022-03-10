using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;

namespace Inprotech.Integration.IPPlatform.FileApp.Comparers
{
    public class FileTrademarkComparableClassProvider : IGoodsServicesProvider
    {
        public IEnumerable<CaseText> Retrieve(InprotechKaizen.Model.Cases.Case @case)
        {
            // To block class text to be compared in case comparison.
            // The Goods Services population method is different, so when class comparison for FILE is available, it should consider the below from FileTrademarkClassBuilder;
            // It should also consider how the case text is to be applied, see IGoodsServices, IGoodsServicesUpdater
            //
            //IEnumerable<CaseText> GoodsAndServicesInPreferredLanguage(InprotechCase @case)
            //{
            //var goodsServicesLanguage = _siteControlReader.Read<int?>(SiteControls.FILEDefaultLanguageforGoodsandServices);
            //
            //return @case.GoodsAndServices
            //                   .Where(_ => _.Language == null || _.Language == goodsServicesLanguage)
            //                   .GroupBy(t => t.Class)
            //                   .Select(g => g.OrderByDescending(_ => _.Language).ThenByDescending(t => t.Number).First())
            //                   .ToArray();
            //} 
            //

            return Enumerable.Empty<CaseText>();
        }
    }
}