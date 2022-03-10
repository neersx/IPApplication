using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Copy : CaseTypePicklist
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyCaseTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseTypePicklist = new PickList(driver).ById("case-type-picklist");
            caseTypePicklist.OpenPickList(CaseTypePicklistDbSetup.ExistingCaseType3);
            caseTypePicklist.DuplicateRow(0);

            var pageDetails = new CaseTypeDetailPage(driver);
            Assert.AreEqual("3", pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is same");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(CaseTypePicklistDbSetup.ExistingCaseType3, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is same");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("J");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(CaseTypePicklistDbSetup.CaseTypeToBeAdded);

            pageDetails.Save();

            caseTypePicklist.SearchFor(CaseTypePicklistDbSetup.CaseTypeToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(CaseTypePicklistDbSetup.CaseTypeToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }
}