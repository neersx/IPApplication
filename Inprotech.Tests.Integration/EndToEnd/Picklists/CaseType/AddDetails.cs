using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class AddDetails : CaseTypePicklist
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddCaseTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseTypePicklist = new PickList(driver).ById("case-type-picklist");
            caseTypePicklist.SearchButton.Click();
            caseTypePicklist.AddPickListItem();

            var pageDetails = new CaseTypeDetailPage(driver);
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Description is equal");

            pageDetails.DefaultsTopic.Code.SendKeys("J");
            pageDetails.DefaultsTopic.Description.SendKeys(CaseTypePicklistDbSetup.CaseTypeToBeAdded);
            pageDetails.Save();

            Assert.AreEqual(CaseTypePicklistDbSetup.CaseTypeToBeAdded, caseTypePicklist.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.IsTrue(caseTypePicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            caseTypePicklist.SearchFor(CaseTypePicklistDbSetup.CaseTypeToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(CaseTypePicklistDbSetup.CaseTypeToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }
}