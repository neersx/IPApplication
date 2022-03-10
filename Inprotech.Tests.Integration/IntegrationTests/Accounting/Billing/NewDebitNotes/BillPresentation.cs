using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.NewDebitNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class BillPresentation : IntegrationTest
    {
        [TearDown]
        public void CleanUp()
        {
            SiteControlRestore.ToDefault(SiteControls.NarrativeTranslate);
        }

        [Test]
        public void NarrativesTranslated()
        {
            var fixture = DbSetup.Do(x =>
            {
                new Users(x.DbContext).Create();

                var narrativeTranslate = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.NarrativeTranslate);
                narrativeTranslate.BooleanValue = true;

                var narrative = x.InsertWithNewId(new Narrative
                {
                    NarrativeCode = RandomString.Next(3),
                    NarrativeTitle = RandomString.Next(20),
                    NarrativeText = RandomString.Next(20)
                }, _ => _.NarrativeId);

                var dutchLanguageId = x.DbContext.Set<TableCode>().Single(_ => _.TableTypeId == (short) TableTypes.Language && _.UserCode == "nl").Id;
                var germanLanguageId = x.DbContext.Set<TableCode>().Single(_ => _.TableTypeId == (short) TableTypes.Language && _.UserCode == "de").Id;

                var narrativeInDutch = x.Insert(new NarrativeTranslation
                {
                    NarrativeId = narrative.NarrativeId,
                    LanguageId = dutchLanguageId,
                    TranslatedText = "dutch"
                });

                var narrativeInGerman = x.Insert(new NarrativeTranslation
                {
                    NarrativeId = narrative.NarrativeId,
                    LanguageId = germanLanguageId,
                    TranslatedText = "german"
                });

                return new
                {
                    narrative.NarrativeId,
                    BaseNarrativeText = narrative.NarrativeText,

                    GermanTranslation = narrativeInGerman.TranslatedText,
                    GermanLangaugeId = germanLanguageId,

                    DutchTranslation = narrativeInDutch.TranslatedText,
                    DutchLanguageId = dutchLanguageId
                };
            });

            var baseNarrativeText = BillingService.GetTranslatedNarrativeText(fixture.NarrativeId, null);

            Assert.AreEqual(fixture.BaseNarrativeText, baseNarrativeText, "When no language Id is passed in, it should return base narrative text");

            var germanTranslation = BillingService.GetTranslatedNarrativeText(fixture.NarrativeId, fixture.GermanLangaugeId);

            Assert.AreEqual(fixture.GermanTranslation, germanTranslation, "When german language Id is passed in, it should return german narrative text");

            var dutchTranslation = BillingService.GetTranslatedNarrativeText(fixture.NarrativeId, fixture.DutchLanguageId);

            Assert.AreEqual(fixture.DutchTranslation, dutchTranslation, "When dutch language Id is passed in, it should return dutch narrative text");

            var fallbackToBaseNarrativeText = BillingService.GetTranslatedNarrativeText(fixture.NarrativeId, Fixture.Integer());

            Assert.AreEqual(fixture.BaseNarrativeText, fallbackToBaseNarrativeText, "When an unknown language Id is passed in, it should return base narrative text");
        }
    }
}