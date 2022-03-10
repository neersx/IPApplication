using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SanityCheckCaseMaintenance : IntegrationTest
    {
        CaseSanityCheckRuleDetails _data;

        [SetUp]
        public void Setup()
        {
            _data = new SanityCheckCasesDbSetup().SetCaseSanityData();
        }

        [TestCase(BrowserType.Chrome)]
        public void AddEditDeleteNewRule(BrowserType browserType)
        {
            const string newRule = "new rule - e2e";
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/sanity-check/case");

            var searchPage = new CaseSearch(driver);
            searchPage.AddButton.Click();
            driver.WaitForAngular();

            var maintenancePage = new CaseMaintenancePage(driver);
            maintenancePage.SanityRuleRelatedFields.DisplayMessage.Input.SendKeys(newRule);
            maintenancePage.SanityRuleRelatedFields.DisplayMessage.Input.SendKeys(Keys.Tab);
            Assert.AreEqual(newRule, maintenancePage.SanityRuleRelatedFields.RuleDescription.Text, "Rule description defaults from display message");
            
            maintenancePage.SaveButton.Click();

            maintenancePage.BackButton.Click();
            driver.WaitForAngular();

            searchPage.SanityRuleRelatedFields.RuleDescription.Input.SendKeys(newRule);
            searchPage.SearchButton.Click();

            driver.WaitForAngular();
            Assert.AreEqual(1, searchPage.CaseSanityCheckGrid.Rows.Count, "The new rule is added and searchable");
            searchPage.CaseSanityCheckGrid.Edit(0);

            maintenancePage.CaseCharacteristics.Office.EnterAndSelect("e2e");
            maintenancePage.CaseCharacteristics.CaseType.EnterAndSelect("e2e");
            maintenancePage.CaseCharacteristics.Jurisdiction.EnterAndSelect("e2e");
            maintenancePage.CaseCharacteristics.PropertyType.EnterAndSelect("e2e");
            maintenancePage.CaseCharacteristics.CaseCategory.EnterAndSelect("e2e");
            maintenancePage.CaseCharacteristics.SubType.EnterAndSelect("e2e");
            maintenancePage.CaseCharacteristics.Basis.EnterAndSelect("e2e");
            maintenancePage.NameRelatedFields.NameType.EnterAndSelect("e2e");
            maintenancePage.InstructionRelatedFields.InstructionType.EnterAndSelect("e2e");
            maintenancePage.InstructionRelatedFields.Characteristic.EnterAndSelect("e2e");
            maintenancePage.EventRelatedFields.Event.EnterAndSelect("e2e");
            maintenancePage.SaveButton.Click();

            maintenancePage.BackButton.Click();
            driver.WaitForAngular();

            Assert.AreEqual(1, searchPage.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 1 row for the new rule");

            Assert.AreEqual(_data.CaseCharacteristics.CaseType.Name, searchPage.CaseSanityCheckGrid.CaseTypeColumn(0).Text, "Case type column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.Office.Name, searchPage.CaseSanityCheckGrid.CaseOfficeColumn(0).Text, "Case office column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.PropertyType.Name, searchPage.CaseSanityCheckGrid.PropertyTypeColumn(0).Text, "Property type column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.CaseCategory.Name, searchPage.CaseSanityCheckGrid.CaseCategoryColumn(0).Text, "Case category column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.SubType.Name, searchPage.CaseSanityCheckGrid.SubTypeColumn(0).Text, "Sub type column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.Basis.Name, searchPage.CaseSanityCheckGrid.BasisColumn(0).Text, "Basis column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.Jurisdiction.Name, searchPage.CaseSanityCheckGrid.JurisdictionColumn(0).Text, "Jurisdiction column text displayed correctly");

            searchPage.CaseSanityCheckGrid.SelectIpCheckbox(0);
            searchPage.BulkMenuButton.Click();
            searchPage.DeleteSelectedOption.Click();
            searchPage.DeletePopup.Click();
            driver.WaitForAngular();

            Assert.AreEqual(0, searchPage.CaseSanityCheckGrid.Rows.Count, "CaseSanityCheckGrid is refreshed and the new rule is deleted");
        }

        [TestCase(BrowserType.Chrome)]
        public void VerifyThatRuleNavigationWorks(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/sanity-check/case");

            var searchPage = new CaseSearch(driver);
            searchPage.SanityRuleRelatedFields.RuleDescriptionElement.SendKeys("e2e");
            searchPage.SearchButton.Click();

            Assert.AreEqual(4, searchPage.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 5 rows with 'e2e' in the rule description");

            searchPage.CaseSanityCheckGrid.SelectIpCheckbox(0);
            searchPage.BulkMenuButton.Click();
            searchPage.EditSelectedOption.Click();

            var page = new CaseMaintenancePage(driver);
            Assert.AreEqual(_data.SanityCheckRule2.RuleDescription, page.SanityRuleRelatedFields.RuleDescription.Text, $"First sanity check rule is displayed as - {_data.SanityCheckRule2.RuleDescription}");
            page.NextButton.Click();
            driver.WaitForAngular();

            Assert.AreEqual(_data.SanityCheckRule3.RuleDescription, page.SanityRuleRelatedFields.RuleDescription.Text, $"Second sanity check rule is displayed - {_data.SanityCheckRule3.RuleDescription}");
        }
    }
}