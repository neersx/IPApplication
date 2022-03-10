using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public interface ICpaXmlConverter
    {
        string Convert(string xmlData);
    }

    public class CpaXmlConverter : ICpaXmlConverter
    {
        readonly IOfficialNumbersConverter _officialNumbersConverter;
        readonly ITitlesConverter _titlesConverter;
        readonly IPriorityClaimsConverter _priorityClaimsConverter;
        readonly INamesConverter _namesConverter;
        readonly IProceduralStepsAndEventsConverter _proceduralStepsAndEventsConverter;
        readonly IOpsData _opsData;

        public CpaXmlConverter(IOfficialNumbersConverter officialNumbersConverter,
                               ITitlesConverter titlesConverter,
                               IPriorityClaimsConverter priorityClaimsConverter,
                               INamesConverter namesConverter,
                               IProceduralStepsAndEventsConverter proceduralStepsAndEventsConverter,
                               IOpsData opsData)
        {
            _officialNumbersConverter = officialNumbersConverter;
            _titlesConverter = titlesConverter;
            _priorityClaimsConverter = priorityClaimsConverter;
            _namesConverter = namesConverter;
            _proceduralStepsAndEventsConverter = proceduralStepsAndEventsConverter;
            _opsData = opsData;
        }

        public string Convert(string xmlData)
        {
            var patentData = _opsData.GetPatentData(xmlData);
            var biblioData = _opsData.GetBibliographicData(xmlData);
            var registerDocument = patentData.registersearch.registerdocuments.First().registerdocument.First();

            var transaction = new Transaction {TransactionHeader = new TransactionHeader(new SenderDetails("EPO"))};
            var transactionBody = new TransactionBody(TransactionCodeType.CaseImport);
            var caseDetails = transactionBody.CreateCaseDetails("Patent", biblioData.country);
            caseDetails.CaseTypeCode = "Property";
            
            _officialNumbersConverter.Convert(biblioData, caseDetails);

            _titlesConverter.Convert(patentData, biblioData, caseDetails);

            _priorityClaimsConverter.Convert(biblioData, caseDetails);

            _namesConverter.Convert(biblioData, caseDetails);

            _proceduralStepsAndEventsConverter.Convert(registerDocument, caseDetails);

            transaction.TransactionBody.Add(transactionBody);

            return CpaXmlHelper.Serialize(transaction);
        }
    }
}
