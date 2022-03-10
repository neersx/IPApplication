using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public class GoodsServicesBuilder : IBuilder<XElement>
    {
        public string ClassNumber { get; set; }

        public Dictionary<string, string> KindCodeClassNumberPair { get; set; }

        public string FirstUsedDate { get; set; }

        public string FirstUsedInCommerceDate { get; set; }

        public string GoodsServicesDescription { get; set; }

        XElement GoodsServicesTextForOtherClassification { get; set; }

        public XElement Build()
        {
            var gs = new List<XElement> {BuildClassDescriptions()};
            if (GoodsServicesTextForOtherClassification != null)
            {
                gs.Add(GoodsServicesTextForOtherClassification);
            }

            return new XElement(
                                Ns.Trademark + "GoodsServices",
                                new XElement(Ns.Trademark + "GoodsServicesClassificationBag",
                                             BuildGoodsServicesClassification()
                                            ),
                                new XElement(Ns.Trademark + "NationalFilingBasis",
                                             BuildFirstUsedDates()
                                            ),
                                new XElement(Ns.Trademark + "ClassDescriptionBag",
                                             gs));
        }

        IEnumerable<XElement> BuildGoodsServicesClassification()
        {
            return KindCodeClassNumberPair != null
                ? KindCodeClassNumberPair.Select(
                                                 _ => new XElement(Ns.Trademark + "GoodsServicesClassification",
                                                                   new XElement(Ns.Trademark + "ClassificationKindCode", _.Key),
                                                                   new XElement(Ns.Trademark + "ClassNumber", _.Value)
                                                                  )
                                                )
                : new[]
                {
                    new XElement(Ns.Trademark + "GoodsServicesClassification",
                                 new XElement(Ns.Trademark + "ClassificationKindCode", "Nice"),
                                 new XElement(Ns.Trademark + "ClassNumber", ClassNumber ?? Fixture.String())
                                )
                };
        }

        IEnumerable<XElement> BuildFirstUsedDates()
        {
            if (!string.IsNullOrWhiteSpace(FirstUsedDate))
            {
                yield return new XElement(Ns.Trademark + "FirstUsedDate", FirstUsedDate);
            }

            if (!string.IsNullOrWhiteSpace(FirstUsedInCommerceDate))
            {
                yield return new XElement(Ns.Trademark + "FirstUsedCommerceDate", FirstUsedInCommerceDate);
            }
        }

        XElement BuildClassDescriptions()
        {
            var c = KindCodeClassNumberPair ?? new Dictionary<string, string>();
            var cn = c.Where(_ => _.Key == "Nice").Select(_ => _.Value).FirstOrDefault();

            return
                new XElement(Ns.Trademark + "ClassDescription",
                             new XElement(Ns.Trademark + "ClassNumber", cn ?? ClassNumber ?? Fixture.String()),
                             new XElement(Ns.Trademark + "GoodsServicesDescriptionText",
                                          GoodsServicesDescription)
                            );
        }

        XElement BuildAlternateClassDescriptions(string description)
        {
            var c = KindCodeClassNumberPair ?? new Dictionary<string, string>();
            var cn = c.Where(_ => _.Key == "Primary").Select(_ => _.Value).FirstOrDefault();

            return
                new XElement(Ns.Trademark + "ClassDescription",
                             new XElement(Ns.Trademark + "NationalClassNumber", cn ?? ClassNumber ?? Fixture.String()),
                             new XElement(Ns.Trademark + "GoodsServicesDescriptionText",
                                          description)
                            );
        }

        public GoodsServicesBuilder WithAlternateGoodsServicesDescription(string description, string classification)
        {
            GoodsServicesTextForOtherClassification = BuildAlternateClassDescriptions(description);
            return this;
        }
    }

    public static class GoodsServicesXElementExt
    {
        public static XElement InGoodsServicesBag(this XElement goodsServicesElement)
        {
            return new XElement(Ns.Trademark + "GoodsServicesBag", goodsServicesElement);
        }
    }
}