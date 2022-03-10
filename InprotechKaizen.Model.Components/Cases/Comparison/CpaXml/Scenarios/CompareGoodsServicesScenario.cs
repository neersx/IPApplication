using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareGoodsServicesScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            return (caseDetails.GoodsServicesDetails ?? Enumerable.Empty<GoodsServicesDetails>())
                .Select(gs =>
                            new ComparisonScenario<Models.GoodsServices>(
                                                                         new Models.GoodsServices
                                                                         {
                                                                             Class = gs.ReadOnlyClass(),
                                                                             FirstUsedDate = gs.ReadOnlyFirstUsedDate(),
                                                                             FirstUsedDateInCommerce = gs.ReadOnlyFirstUsedDateInCommerce(),
                                                                             Text = gs.ReadOnlyGoodsServicesText(),
                                                                             LanguageCode = gs.ReadOnlyLanguageCode()
                                                                         }, ComparisonType.GoodsServices));
        }
        
        public bool IsAllowed(string source)
        {
            return true;
        }
    }

    public static class GoodsServicesExt
    {
        static ClassDescription ReadClassDescription(this GoodsServicesDetails detail)
        {
            return detail.ClassDescriptionDetails.ClassDescriptions.FirstOrDefault();
        }

        public static string ReadOnlyClass(this GoodsServicesDetails goodsServicesDetails)
        {
            var classDescription = goodsServicesDetails.ReadClassDescription();
            return classDescription?.ClassNumber;
        }

        public static string ReadOnlyFirstUsedDate(this GoodsServicesDetails goodsServicesDetails)
        {
            var classDescription = goodsServicesDetails.ReadClassDescription();
            return classDescription?.FirstUsedDate;
        }

        public static string ReadOnlyFirstUsedDateInCommerce(this GoodsServicesDetails goodsServicesDetails)
        {
            var classDescription = goodsServicesDetails.ReadClassDescription();
            return classDescription?.FirstUsedDateInCommerce;
        }

        public static string ReadOnlyGoodsServicesText(this GoodsServicesDetails goodsServicesDetails)
        {
            var classDescription = goodsServicesDetails.ReadClassDescription();

            if (classDescription?.GoodsServicesDescription == null || !classDescription.GoodsServicesDescription.Any()) return null;

            return classDescription.GoodsServicesDescription.First().Value;
        }

        public static string ReadOnlyLanguageCode(this GoodsServicesDetails goodsServicesDetails)
        {
            var classDescription = goodsServicesDetails.ReadClassDescription();

            if (classDescription?.GoodsServicesDescription == null || !classDescription.GoodsServicesDescription.Any()) return null;

            return classDescription.GoodsServicesDescription.First().LanguageCode;
        }
    }
}