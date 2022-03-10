using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TranslatedNarrative : IntegrationTest
    {
        dynamic _dbData;

        [SetUp]
        public void Setup()
        {
            DbSetup.Do(x =>
            {
                var narrativeTranslate = x.DbContext.Set<SiteControl>()
                                           .Single(_ => _.ControlId == SiteControls.NarrativeTranslate);
                narrativeTranslate.BooleanValue = true;
                var staffName = new NameBuilder(x.DbContext).CreateStaff();
                var userSetup = new Users(x.DbContext) { Name = staffName }.WithPermission(ApplicationTask.MaintainTimeViaTimeRecording);
                var user = userSetup.Create();
                new WipTemplateBuilder(x.DbContext).Create("E2E");
                new WipTemplateBuilder(x.DbContext).Create("NEW");

                var entityName = new NameBuilder(x.DbContext).Create("E2E-Entity");
                x.Insert(new SpecialName(true, entityName));

                var debtorNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);
                var debtor1 = new NameBuilder(x.DbContext).CreateClientOrg("E2E");
                x.Insert(new ClientDetail(debtor1.Id));
                var debtor2 = new NameBuilder(x.DbContext).CreateClientOrg("E2E2");
                x.Insert(new ClientDetail(debtor2.Id));

                var @case = new CaseBuilder(x.DbContext).Create("e2e", null, user.Username, null, null, false);
                @case.CaseNames.Add(new CaseName(@case, debtorNameType, debtor1, 100) { BillingPercentage = 100 });

                var narrative = new NarrativeBuilder(x.DbContext).Create("e2e");
                x.Insert(new NameLanguage { NameId = debtor1.Id, Sequence = 1, LanguageId = 4707 });
                x.Insert(new NameLanguage { NameId = debtor2.Id, Sequence = 1, LanguageId = 4706 });
                x.Insert(new NarrativeTranslation { NarrativeId = narrative.NarrativeId, LanguageId = 4707, TranslatedText = $"German - {narrative.NarrativeTitle}" });
                x.Insert(new NarrativeTranslation { NarrativeId = narrative.NarrativeId, LanguageId = 4706, TranslatedText = $"French - {narrative.NarrativeTitle}" });

                x.DbContext.SaveChanges();

                _dbData = new
                {
                    StaffName = staffName,
                    User = user,
                    CaseDebtor = debtor1,
                    Debtor = debtor2,
                    Case = @case,
                    Narrative = narrative,
                    EntityId = entityName.Id
                };
            });
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.NarrativeTranslate);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void GetTranslatedNarrativeWhereApplicable(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.AddButton.ClickWithTimeout();

            var entriesList = page.Timesheet;
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var narrativePicker = details.Narrative;
            narrativePicker.EnterAndSelect("e2e");
            var narrativeText = details.NarrativeText;
            Assert.AreEqual(_dbData.Narrative.NarrativeText, narrativeText.Value(), "Expected Narrative text to be defaulted");
            
            var editableRow = new TimeRecordingPage.EditableRow(driver, page.Timesheet, 0);
            editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
            
            narrativePicker = details.Narrative;
            narrativePicker.Clear();
            narrativePicker.EnterAndSelect("e2e");
            narrativeText = details.NarrativeText;
            Assert.IsTrue(narrativeText.Value().StartsWith("German"), "Expected Narrative text to be translated for case debtor");

            editableRow.CaseRef.Clear();
            editableRow.Name.Clear();
            editableRow.Name.EnterExactSelectAndBlur(_dbData.Debtor.NameCode);
            narrativePicker.Clear();
            narrativePicker.EnterAndSelect("e2e");
            narrativeText = details.NarrativeText;
            Assert.IsTrue(narrativeText.Value().StartsWith("French"), "Expected Narrative text to be translated for the debtor");
        }
    }
}
