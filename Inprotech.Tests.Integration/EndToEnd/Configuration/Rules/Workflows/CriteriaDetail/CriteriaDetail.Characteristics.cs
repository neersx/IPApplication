using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail
{
    [TestFixture]
    public class CriteriaDetailCharacteristics : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CriteriaCharacteristicsSuccessMessages(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData dataFixture;
            using (var setup = new CriteriaDetailDbSetup())
            {
                dataFixture = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");

            CriteriaHelper.GoToMaintenancePage(driver, dataFixture.CriteriaId, dataFixture.ChildCriteriaId);

            var page = new CriteriaDetailPage(driver);
            var popup = new CommonPopups(driver);
            var infoMessage = By.CssSelector("p[translate='workflows.maintenance.save']");

            page.CharacteristicsTopic.CriteraName.Input("test");
            page.Save.Click();
            Assert.NotNull(popup.FlashAlert(), "Standard Flash alert if only critera name is changed");

            page.CharacteristicsTopic.ProtectCriteriaYes.Input.WithJs().Click();
            page.Save.Click();
            Assert.NotNull(popup.FlashAlert(), "Standard Flash alert if only protected status is changed");

            var caseType = new PickList(driver).ByName("ip-maintain-characteristics", "caseType");
            var propertyType = new PickList(driver).ByName("ip-maintain-characteristics", "propertyType");

            caseType.EnterAndSelect(dataFixture.CaseTypeName);

            propertyType.EnterAndSelect(dataFixture.PropertyTypeName);

            page.Save.Click();
            Assert.NotNull(popup.InfoModal.FindElement(infoMessage), "Information message for policing when any other field is changed");
            popup.InfoModal.Ok();

            page.CharacteristicsTopic.CriteraName.Clear();
            page.CharacteristicsTopic.CriteraName.Input("test");
            page.CharacteristicsTopic.ProtectCriteriaNo.Input.WithJs().Click();
            page.Save.Click();
            Assert.NotNull(popup.FlashAlert(), "Standard Flash alert if only criteria name and protected status is changed");

            page.CharacteristicsTopic.CriteraName.Clear();
            page.CharacteristicsTopic.CriteraName.Input("test");
            page.CharacteristicsTopic.ProtectCriteriaYes.Input.WithJs().Click();
            caseType.Typeahead.Clear();
            propertyType.Typeahead.Clear();
            page.Save.Click();
            Assert.NotNull(popup.InfoModal.FindElement(infoMessage), "Information message for policing when any other field is changed");
            popup.InfoModal.Ok();

            var newCheckedInUse = page.CharacteristicsTopic.InUseYes.Input.WithJs().IsChecked() ? page.CharacteristicsTopic.InUseNo : page.CharacteristicsTopic.InUseYes;

            newCheckedInUse.Input.WithJs().Click();
            page.Save.Click();
            Assert.NotNull(popup.InfoModal.FindElement(infoMessage), "Information message for policing when any other field is changed");
            popup.InfoModal.Ok();

            ReloadPage(driver);
            Assert.IsTrue(newCheckedInUse.Input.WithJs().IsChecked());

            var criteriaId = 0;
            var alreadyUsedname = string.Empty;
            using (var setup = new DbSetup())
            {
                alreadyUsedname = Fixture.Prefix("Criteria");
                setup.InsertWithNewId(new Criteria
                                          {
                                              Description = alreadyUsedname,
                                              PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                              UserDefinedRule = 1,
                                              RuleInUse = 1,
                                              ActionId = dataFixture.ActionId
                                          });

                criteriaId = setup.InsertWithNewId(new Criteria
                                                       {
                                                           Description = Fixture.Prefix("Criteria2"),
                                                           PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                           UserDefinedRule = 1,
                                                           RuleInUse = 1,
                                                           ActionId = dataFixture.ActionId
                                                       }).Id;
            }

            driver.Visit($"/#/configuration/rules/workflows/{criteriaId}");
            page.CharacteristicsTopic.CriteraName.Clear();
            page.CharacteristicsTopic.CriteraName.Input(alreadyUsedname);
            page.CharacteristicsTopic.InUseNo.Click();
            page.CharacteristicsTopic.InUseYes.Click();

            page.Save.Click();
            Assert.NotNull(popup.AlertModal);
            popup.AlertModal.Ok();

            page.CharacteristicsTopic.CriteraName.Clear();
            page.CharacteristicsTopic.CriteraName.Input(Fixture.Prefix("Criteria3"));
            page.CharacteristicsTopic.InUseNo.Click();
            page.CharacteristicsTopic.InUseYes.Click();

            page.Save.Click();
            Assert.NotNull(popup.AlertModal);

            popup.AlertModal.Ok();

            //https://github.com/mozilla/geckodriver/issues/1151
            page.RevertButton.Click();  //edit mode discard
            page.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void BlockProtectingCriteriaIfParentUnprotected(BrowserType browserType)
        {
            int criteriaId;
            using (var setup = new DbSetup())
            {
                criteriaId = setup.InsertWithNewId(new Criteria
                                                       {
                                                           Description = Fixture.Prefix("Criteria"),
                                                           PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                           UserDefinedRule = 1
                                                       }).Id;

                var parentCriteriaId = setup.InsertWithNewId(new Criteria
                                                                 {
                                                                     Description = Fixture.Prefix("ParentCriteria"),
                                                                     PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                     UserDefinedRule = 1
                                                                 }).Id;

                setup.Insert(new Inherits(criteriaId, parentCriteriaId));
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows/" + criteriaId);

            var page = new CriteriaDetailPage(driver);
            Assert.True(page.CharacteristicsTopic.ProtectCriteriaYes.IsDisabled);
            Assert.True(page.CharacteristicsTopic.ProtectCriteriaNo.IsDisabled);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void BlockUnprotectingCriteriaIfChildProtected(BrowserType browserType)
        {
            int criteriaId;
            using (var setup = new DbSetup())
            {
                criteriaId = setup.InsertWithNewId(new Criteria
                                                       {
                                                           Description = Fixture.Prefix("Criteria"),
                                                           PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                           UserDefinedRule = 0
                                                       }).Id;

                var childCriteriaId = setup.InsertWithNewId(new Criteria
                                                                {
                                                                    Description = Fixture.Prefix("ChildCriteria"),
                                                                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                    UserDefinedRule = 0
                                                                }).Id;

                setup.Insert(new Inherits(childCriteriaId, criteriaId));
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows/" + criteriaId);

            var page = new CriteriaDetailPage(driver);
            Assert.True(page.CharacteristicsTopic.ProtectCriteriaYes.IsDisabled);
            Assert.True(page.CharacteristicsTopic.ProtectCriteriaNo.IsDisabled);
        }
    }
}