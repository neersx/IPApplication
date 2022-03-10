using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Name
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SearchByNames : IntegrationTest
    {
        NameSanityCheckRuleDetails _data;

        [SetUp]
        public void Setup()
        {
            _data = new SanityCheckNamesDbSetup().SetupNamesSanityData();
        }

        [TestCase(BrowserType.Chrome)]
        public void SearchWithCaseCharacteristics(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/sanity-check/name");

            var page = new NameSearch(driver);

            Assert.True(page.SanityRuleRelatedFields.IncludeInUse.IsChecked);
            page.SanityRuleRelatedFields.IncludeInUse.Click();
            page.SanityRuleRelatedFields.RuleDescriptionElement.SendKeys("e2e");
            page.SearchButton.Click();
            Assert.AreEqual(5, page.SanityCheckGrid.Rows.Count, "Names sanity check results returned 5 rows with 'e2e' in the rule description");

            page.Individual.Click();
            page.SearchButton.Click();
            Assert.AreEqual(2, page.SanityCheckGrid.Rows.Count, "Names sanity check results returned 1 row for individual");

            page.Staff.Click();
            page.SearchButton.Click();
            Assert.AreEqual(1, page.SanityCheckGrid.Rows.Count, "Names sanity check results returned 2 row for individual and staff");

            page.Individual.Click();
            page.SearchButton.Click();
            Assert.AreEqual(1, page.SanityCheckGrid.Rows.Count, "Names sanity check results returned 1 row for staff");
        }
    }
}