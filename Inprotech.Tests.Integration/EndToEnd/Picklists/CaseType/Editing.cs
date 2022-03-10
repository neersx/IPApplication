using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Editing : CaseTypePicklist
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSaveCaseTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingCaseType = _scenario.ExistingApplicationCaseType;

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseTypePicklist = new PickList(driver).ById("case-type-picklist");
            caseTypePicklist.OpenPickList(_scenario.CaseTypeName);
            caseTypePicklist.EditRow(0);

            var pageDetails = new CaseTypeDetailPage(driver);
            Assert.AreEqual(existingCaseType.Code, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsTrue(pageDetails.DefaultsTopic.Code.GetAttribute("disabled").Equals("true"), "Ensure Code is disabled");
            Assert.AreEqual(existingCaseType.Name, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");

            var editedName = existingCaseType.Name + " edited";
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(editedName);
            pageDetails.Save();

            caseTypePicklist.SearchFor(editedName);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckActualCaseTypeInUse(BrowserType browserType)
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
            pageDetails.DefaultsTopic.Description.SendKeys("e2e");
            var actualCaseType = new PickList(driver).ByName(string.Empty, "pkActualCaseType");
            driver.WaitForAngularWithTimeout();
            actualCaseType.EnterAndSelect("Properties");
            driver.WaitForAngularWithTimeout();
            pageDetails.Save();

            new CommonPopups(driver).AlertModal.Ok();

            Assert.IsTrue(actualCaseType.HasError, "Actual case type should be unique");

            //https://github.com/mozilla/geckodriver/issues/1151

            pageDetails.Discard(); // edit mode discard
            pageDetails.Discard(); // discard confirm.
        }
    }
}