using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules;
using Inprotech.Web.Cases.EventRules.Models;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class DocumentsServiceFacts : FactBase
    {
        [Fact]
        public void ShouldReturnDocuments()
        {
            var f = new DocumentsServiceFixture();
            var documentsDetails = new List<DocumentsDetails>
            {
                new DocumentsDetails
                {
                    LeadTime = Fixture.Short(),
                    PeriodType = Fixture.String(),
                    Frequency = Fixture.Short(),
                    LetterName = Fixture.String(),
                    LetterNo = Fixture.Short(),
                    LetterFee = Fixture.String(),
                    FreqPeriodType = null,
                    MaxLetters = Fixture.Short(),
                    PayFeeCode = Fixture.Short()
                }
            };

            f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns("Letter Description");
            f.StaticTranslator.Translate("caseview.eventRules.documents.maxLettersLiteral", Arg.Any<IEnumerable<string>>()).Returns("A maximum of {0} of this document will be produced");
            f.StaticTranslator.Translate("caseview.eventRules.documents.raiseChargeLiteral", Arg.Any<IEnumerable<string>>()).Returns("{0} using saved estimate");

            var r = f.Subject.GetDocuments(documentsDetails);

            var documentsInfos = r as DocumentsInfo[] ?? r.ToArray();
            var info = documentsInfos.First();
            Assert.Equal(1, documentsInfos.Length);
            Assert.Equal("Letter Description", info.FormattedDescription);
            Assert.Equal(documentsDetails.First().MaxLetters, info.MaxProductionValue);
            if (info.RequestLetterLiteralFlag != null) Assert.Equal(0, (int) info.RequestLetterLiteralFlag);
        }
    }

    public class DocumentsServiceFixture : IFixture<DocumentsService>
    {
        public IStaticTranslator StaticTranslator { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public IEventRulesHelper EventRulesHelper { get; }

        public DocumentsServiceFixture()
        {
            StaticTranslator = Substitute.For<IStaticTranslator>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            EventRulesHelper = Substitute.For<IEventRulesHelper>();
            Subject = new DocumentsService(PreferredCultureResolver, StaticTranslator, EventRulesHelper);
        }

        public DocumentsService Subject { get; }
    }
}
