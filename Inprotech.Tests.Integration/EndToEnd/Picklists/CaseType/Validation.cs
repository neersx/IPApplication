using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Validation : CaseTypePicklist
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseTypePicklist = new PickList(driver).ById("case-type-picklist");
            caseTypePicklist.SearchButton.Click();
            caseTypePicklist.AddPickListItem();

            var pageDetails = new CaseTypeDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.IsDisabled(), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Code.SendKeys("J");
            driver.WaitForAngular();
            pageDetails.Save();

            Assert.IsTrue(new TextField(driver, "value").HasError, "Description is mandatory");

            pageDetails.DefaultsTopic.Code.Clear();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code is mandatory");

            pageDetails.DefaultsTopic.Code.SendKeys("AAA");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be maximum 2 characters");

            pageDetails.DefaultsTopic.Description.SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 50 characters");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("J");
            Assert.IsFalse(new TextField(driver, "code").HasError);

            driver.WaitForAngular();
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys("AAA");
            Assert.IsFalse(new TextField(driver, "value").HasError);

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckForUniqueCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingCaseType = _scenario.ExistingApplicationCaseType;

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseTypePicklist = new PickList(driver).ById("case-type-picklist");
            caseTypePicklist.SearchButton.Click();
            caseTypePicklist.AddPickListItem();

            var pageDetails = new CaseTypeDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys(existingCaseType.Code);
            pageDetails.DefaultsTopic.Description.SendKeys("abcd");
            pageDetails.Save();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("J");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(existingCaseType.Name);
            pageDetails.Save();

            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be unique");

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }
    }
}