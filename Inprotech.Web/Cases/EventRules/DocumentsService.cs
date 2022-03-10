using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules.Models;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;

namespace Inprotech.Web.Cases.EventRules
{
    public interface IDocumentsService
    {
        IEnumerable<DocumentsInfo> GetDocuments(IEnumerable<DocumentsDetails> details);
    }

    public class DocumentsService : IDocumentsService
    {
        const string DocumentsTranslate = "caseview.eventRules.documents.";
        readonly IEventRulesHelper _eventRuleHelper;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _translator;

        public DocumentsService(
            IPreferredCultureResolver preferredCultureResolver,
            IStaticTranslator translator,
            IEventRulesHelper eventRuleHelper
        )
        {
            _preferredCultureResolver = preferredCultureResolver;
            _translator = translator;
            _eventRuleHelper = eventRuleHelper;
        }

        public IEnumerable<DocumentsInfo> GetDocuments(IEnumerable<DocumentsDetails> details)
        {
            var documentsInfo = new List<DocumentsInfo>();
            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();

            foreach (var doc in details)
            {
                var documentsInfoItem = new DocumentsInfo();

                var formattedHeading = FormattedHeading(doc, cultureResolver);

                documentsInfoItem.FormattedDescription = $"{formattedHeading}".MakeSentenceLike();

                if (doc.MaxLetters.HasValue && doc.MaxLetters.GetValueOrDefault() > 0)
                {
                    documentsInfoItem.MaxProductionValue = doc.MaxLetters.Value;
                }

                switch (doc.UpdateEvent)
                {
                    case (short)UpdateEventOption.UpdateEventWhenDocumentProduced:
                        documentsInfoItem.RequestLetterLiteralFlag = (short) UpdateEventOption.UpdateEventWhenDocumentProduced;
                        break;
                    case (short)UpdateEventOption.ProduceDocumentWhenEventUpdated:
                        documentsInfoItem.RequestLetterLiteralFlag = (short) UpdateEventOption.ProduceDocumentWhenEventUpdated;
                        break;
                }

                if (doc.PayFeeCode != (int)RatesCode.NotSet)
                {
                    var raiseChargeLiteral = string.Format($"{_translator.Translate(DocumentsTranslate + "raiseChargeLiteral", cultureResolver)} {_eventRuleHelper.RatesCodeToLocalizedString(doc.PayFeeCode, cultureResolver)}", doc.LetterFee);

                    documentsInfoItem.FeesAndChargesInfo = doc.EstimateFlag.GetValueOrDefault() ? _translator.Translate(DocumentsTranslate + "raiseChargeLiteral", cultureResolver) : raiseChargeLiteral;
                }

                documentsInfo.Add(documentsInfoItem);
            }

            return documentsInfo;
        }

        string FormattedHeading(DocumentsDetails doc, string[] cultureResolver)
        {
            var leadPeriod = !doc.LeadTime.HasValue || doc.LeadTime.GetValueOrDefault() == 0 ? string.Empty : _eventRuleHelper.PeriodTypeToLocalizedString(doc.LeadTime, doc.PeriodType, cultureResolver);

            var untilClause = !doc.StopTime.HasValue || doc.StopTime.GetValueOrDefault() == 0 ? string.Empty : string.Format(_translator.Translate(DocumentsTranslate + "stopLiteral", cultureResolver), _eventRuleHelper.PeriodTypeToLocalizedString(doc.StopTime, doc.StopTimePeriodType, cultureResolver));

            var headingResource = doc.LeadTime.GetValueOrDefault() > 0 ? _translator.Translate(DocumentsTranslate + "sendBeforeDueDate", cultureResolver) : _translator.Translate(DocumentsTranslate + "sendOnDueDate", cultureResolver);

            var repeatClause = !doc.Frequency.HasValue || doc.Frequency.GetValueOrDefault() == 0
                ? string.Empty
                : $"{_translator.Translate(DocumentsTranslate + "repeatLiteral", cultureResolver)} {_eventRuleHelper.PeriodTypeToLocalizedString(doc.Frequency, doc.FreqPeriodType, cultureResolver)}";

            var letterName = "\"" + doc.LetterName + "\"";

            var formattedHeading = string.Format(headingResource, leadPeriod, repeatClause, untilClause, letterName);

            return formattedHeading;
        }
    }
}