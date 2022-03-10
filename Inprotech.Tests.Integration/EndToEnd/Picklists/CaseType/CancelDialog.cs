using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CancelDialog : CaseTypePicklist
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DiscardCancelDialogOnCaseTypeChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseTypePicklist = new PickList(driver).ById("case-type-picklist");
            caseTypePicklist.OpenPickList(_scenario.CaseTypeName);
            caseTypePicklist.AddPickListItem();

            var pageDetails = new CaseTypeDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys("J");
            pageDetails.DefaultsTopic.Description.SendKeys("J");

            pageDetails.Discard();

            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.Code.GetAttribute("value"), "J", "Code is not lost");
            Assert.AreEqual(pageDetails.DefaultsTopic.Description.GetAttribute("value"), "J", "Description is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("code")));
        }
    }
}