using System;
using System.IO;
using System.Xml;
using System.Xml.XPath;
using CPAXML;
using Inprotech.Integration.CaseSource;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public interface ICpaXmlConverter
    {
        string Convert(EligibleCase @case, string appDetails);
    }

    public class CpaXmlConverter : ICpaXmlConverter
    {
        readonly ITsdrSettings _tsdrSettings;
        readonly IApplicantsConverter _applicantsConverter;
        readonly ICriticalDatesConverter _criticalDatesConverter;
        readonly IGoodsServicesConverter _goodsServicesConverter;
        readonly IOtherCriticalDetailsConverter _otherCriticalDetailsConverter;
        readonly IEventsConverter _eventsConverter;

        public CpaXmlConverter(ITsdrSettings tsdrSettings, IApplicantsConverter applicantsConverter,
            ICriticalDatesConverter criticalDatesConverter, IGoodsServicesConverter goodsServicesConverter,
            IOtherCriticalDetailsConverter otherCriticalDetailsConverter, IEventsConverter eventsConverter)
        {
            _tsdrSettings = tsdrSettings;
            _applicantsConverter = applicantsConverter;
            _criticalDatesConverter = criticalDatesConverter;
            _goodsServicesConverter = goodsServicesConverter;
            _otherCriticalDetailsConverter = otherCriticalDetailsConverter;
            _eventsConverter = eventsConverter;
        }

        public string Convert(EligibleCase @case, string appDetails)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (appDetails == null) throw new ArgumentNullException(nameof(appDetails));

            var transaction = new Transaction
                              {
                                  TransactionHeader =
                                      new TransactionHeader(new SenderDetails("USPTO.TSDR"))
                              };
            var transactionBody = new TransactionBody(TransactionCodeType.CaseImport);
            var caseDetails = transactionBody.CreateCaseDetails("Trademark", @case.CountryCode);
            caseDetails.CaseTypeCode = "Property";

            using (var reader = new StringReader(appDetails))
            {
                var navigator = new XPathDocument(reader).CreateNavigator();
                var resolver = new XmlNamespaceManager(navigator.NameTable);
                resolver.AddNamespace("ns2", _tsdrSettings.TrademarkNs.ToString());
                resolver.AddNamespace("ns1", _tsdrSettings.CommonNs.ToString());

                var trademarkNode = navigator.SelectSingleNode("//ns2:Trademark", resolver);
                if (trademarkNode != null)
                {
                    _criticalDatesConverter.Convert(trademarkNode, resolver, caseDetails);

                    _otherCriticalDetailsConverter.Convert(trademarkNode, resolver, caseDetails);

                    _goodsServicesConverter.Convert(trademarkNode, resolver, caseDetails);

                    _eventsConverter.Convert(trademarkNode, resolver, caseDetails);

                    _applicantsConverter.Convert(trademarkNode, resolver, caseDetails);
                }
            }
            transaction.TransactionBody.Add(transactionBody);

            return CpaXmlHelper.Serialize(transaction);
        }
    }
}