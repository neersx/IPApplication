using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SearchByCase : IntegrationTest
    {
        CaseSanityCheckRuleDetails _data;

        [SetUp]
        public void Setup()
        {
            _data = new SanityCheckCasesDbSetup().SetCaseSanityData();
        }

        [TestCase(BrowserType.Chrome)]
        public void SearchWithCaseCharacteristics(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/sanity-check/case");

            var page = new CaseSearch(driver);

            Assert.True(page.SanityRuleRelatedFields.IncludeInUse.IsChecked);
            page.SanityRuleRelatedFields.IncludeInUse.Click();
            page.SanityRuleRelatedFields.RuleDescriptionElement.SendKeys("e2e");
            page.SearchButton.Click();
            Assert.AreEqual(5, page.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 5 rows with 'e2e' in the rule description");

            page.CaseCharacteristics.Office.EnterAndSelect("e2e");
            page.CaseCharacteristics.PropertyType.EnterAndSelect("e2e");
            page.CaseCharacteristics.SubType.EnterAndSelect("e2e");
            page.CaseCharacteristics.CaseType.EnterAndSelect("e2e");
            page.CaseCharacteristics.Jurisdiction.EnterAndSelect("e2e");
            page.CaseCharacteristics.Basis.EnterAndSelect("e2e");
            page.StatusFields.Registered.Click();
            page.SearchButton.Click();
            Assert.AreEqual(4, page.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 4 rows, after adding case characteristics to the search criteria");

            page.NameRelatedFields.Name.EnterAndSelect("e2e");
            page.NameRelatedFields.NameType.EnterAndSelect("e2e");
            page.SearchButton.Click();
            Assert.AreEqual(3, page.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 3 rows, after adding name characteristics to the search criteria");

            page.InstructionRelatedFields.InstructionType.EnterAndSelect("e2e");
            page.SearchButton.Click();
            Assert.AreEqual(2, page.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 2 rows, after adding instructions to the search criteria");

            page.EventRelatedFields.Event.EnterAndSelect("e2e");
            page.SearchButton.Click();
            Assert.AreEqual(1, page.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 1 row, after adding event to the search criteria");

            page.CaseCharacteristics.CaseTypeExclude.Click();
            page.SearchButton.Click();
            Assert.AreEqual(0, page.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 0 rows, after adding exclude for case type");
        }

        [TestCase(BrowserType.Chrome)]
        public void VerifyThatExcludeIconIsDisplayed(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/sanity-check/case");

            var page = new CaseSearch(driver);
            page.CaseCharacteristics.Jurisdiction.SendKeys("e2e");
            page.CaseCharacteristics.JurisdictionExclude.Click();
            page.CaseCharacteristics.SubType.SendKeys("e2e");
            page.CaseCharacteristics.SubTypeExclude.Click();
            page.SanityRuleRelatedFields.IncludeInUse.Click();
            page.SearchButton.Click();
            Assert.AreEqual(1, page.CaseSanityCheckGrid.Rows.Count, "Case sanity check results returned 1 row, after with specific search criteria");

            Assert.AreEqual(_data.SanityCheckRule5.RuleDescription, page.CaseSanityCheckGrid.RuleDescriptionColumn(0).Text, "Rule description displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.CaseType.Name, page.CaseSanityCheckGrid.CaseTypeColumn(0).Text, "Case type column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.Office.Name, page.CaseSanityCheckGrid.CaseOfficeColumn(0).Text, "Case office column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.PropertyType.Name, page.CaseSanityCheckGrid.PropertyTypeColumn(0).Text,"Property type column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.CaseCategory.Name, page.CaseSanityCheckGrid.CaseCategoryColumn(0).Text, "Case category column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.SubType.Name, page.CaseSanityCheckGrid.SubTypeColumn(0).Text, "Sub type column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.Basis.Name, page.CaseSanityCheckGrid.BasisColumn(0).Text, "Basis column text displayed correctly");
            Assert.AreEqual(_data.CaseCharacteristics.Jurisdiction.Name, page.CaseSanityCheckGrid.JurisdictionColumn(0).Text, "Jurisdiction column text displayed correctly");

            Assert.IsTrue(page.CaseSanityCheckGrid.CaseTypeExcludeIcon(0), "Exclude flag displayed for case type");
            Assert.IsTrue(page.CaseSanityCheckGrid.PropertyTypeExcludeIcon(0), "Exclude flag displayed for property type");
            Assert.IsTrue(page.CaseSanityCheckGrid.CaseCategoryExcludeIcon(0), "Exclude flag displayed for case category");
            Assert.IsTrue(page.CaseSanityCheckGrid.SubTypeExcludeIcon(0), "Exclude flag displayed for sub type");
            Assert.IsTrue(page.CaseSanityCheckGrid.BasisExcludeIcon(0), "Exclude flag displayed for basis");
            Assert.IsTrue(page.CaseSanityCheckGrid.JurisdictionExcludeIcon(0), "Exclude flag displayed for jurisdiction");
        }
    }
}