using System.Xml;
using System.Xml.XPath;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public interface IGoodsServicesConverter
    {
        void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails);
    }

    public class GoodsServicesConverter : IGoodsServicesConverter
    {
        public void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var goodsServicesNodes = trademarkNode.Select("ns2:GoodsServicesBag/ns2:GoodsServices", resolver);
            while (goodsServicesNodes.MoveNext())
            {
                var current = goodsServicesNodes.Current;

                var classNumber = XmlTools.GetXmlNodeValue(current,
                    "ns2:GoodsServicesClassificationBag/ns2:GoodsServicesClassification[ns2:ClassificationKindCode = 'Nice']/ns2:ClassNumber", resolver);

                var primaryClassNumber = XmlTools.GetXmlNodeValue(current,
                    "ns2:GoodsServicesClassificationBag/ns2:GoodsServicesClassification[ns2:ClassificationKindCode = 'Primary']/ns2:ClassNumber", resolver);

                if (string.IsNullOrWhiteSpace(primaryClassNumber))
                {
                    primaryClassNumber =
                        XmlTools.GetXmlNodeValue(current,
                    "ns2:GoodsServicesClassificationBag/ns2:GoodsServicesClassification[ns2:ClassificationKindCode = 'Primary']/ns2:NationalClassNumber", resolver);
                }

                var goodsServicesDescription = string.IsNullOrWhiteSpace(classNumber)
                    ? null
                    : XmlTools.GetXmlNodeValue(current,
                        "ns2:ClassDescriptionBag/ns2:ClassDescription[ns2:ClassNumber = " + classNumber + "]/ns2:GoodsServicesDescriptionText", resolver);

                if (string.IsNullOrWhiteSpace(goodsServicesDescription) && !string.IsNullOrWhiteSpace(primaryClassNumber))
                {
                    goodsServicesDescription = XmlTools.GetXmlNodeValue(current,
                        "ns2:ClassDescriptionBag/ns2:ClassDescription[ns2:NationalClassNumber = " + primaryClassNumber + "]/ns2:GoodsServicesDescriptionText", resolver);

                    if (string.IsNullOrWhiteSpace(goodsServicesDescription))
                    {
                        goodsServicesDescription = XmlTools.GetXmlNodeValue(current,
                            "ns2:ClassDescriptionBag/ns2:ClassDescription[ns2:ClassNumber = " + primaryClassNumber + "]/ns2:GoodsServicesDescriptionText", resolver);    
                    }
                }

                var firstUsedDate = XmlTools.GetXmlNodeValue(current, "ns2:NationalFilingBasis/ns2:FirstUsedDate", resolver);

                var firstUsedDateInCommerce = XmlTools.GetXmlNodeValue(current,
                    "ns2:NationalFilingBasis/ns2:FirstUsedCommerceDate", resolver);

                if (string.IsNullOrEmpty(classNumber) &&
                    string.IsNullOrEmpty(goodsServicesDescription)) continue;

                caseDetails.CreateGoodsServicesDetails("Nice",
                    classNumber,
                    goodsServicesDescription ?? classNumber, firstUsedDate,
                    firstUsedDateInCommerce);
            }
        }
    }
}