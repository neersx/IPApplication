using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.NameTypeGroup
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class NameTypeGroupPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _nameTypeGroupDbSetup = new NameTypeGroupDbSetup();
            _scenario = _nameTypeGroupDbSetup.Prepare();
        }

        NameTypeGroupDbSetup _nameTypeGroupDbSetup;
        NameTypeGroupDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddNameTypeGroupDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/nametypes");

            var nameTypeGroupPicklist = new PickList(driver).ById("nametype-group-picklist");
            var nameTypePicklist = new PickList(driver).ById("nametype-picklist");
            var pageDetails = new NameTypeGroupDetailPage(driver);

            nameTypeGroupPicklist.OpenPickList(string.Empty);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region Name Type Group
           
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.GroupName.GetAttribute("value"), "Ensure Group Name is equal");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.NameTypePicklist.GetText(), "Ensure Name Type picklist is equal");
            Assert.Throws<NoSuchElementException>(() => pageDetails.DefaultsTopic.NavigationBar(driver), "Ensure Navigation Bar is not visible");

            pageDetails.DefaultsTopic.GroupName.SendKeys(NameTypeGroupDbSetup.NameTypeGroupToBeAdded);
            nameTypePicklist.EnterAndSelect("Debtor");
            pageDetails.DefaultsTopic.GroupName.ClickWithTimeout();
            nameTypePicklist.EnterAndSelect("Owner");
            pageDetails.Save();

            nameTypeGroupPicklist.SearchFor(NameTypeGroupDbSetup.NameTypeGroupToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameTypeGroupDbSetup.NameTypeGroupToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            #endregion

            #region validate max lenght
            pageDetails.Discard();
            nameTypeGroupPicklist.OpenPickList(string.Empty);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.GroupName.Clear();

            pageDetails.DefaultsTopic.GroupName.SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "groupName").HasError, "Group name should be maximum 50 characters");

            pageDetails.DefaultsTopic.GroupName.Clear();
            pageDetails.DefaultsTopic.GroupName.SendKeys("J");
            nameTypePicklist.EnterAndSelect("Owner");
            Assert.IsFalse(new TextField(driver, "groupName").HasError);
            pageDetails.Save();
            #endregion

            #region for unique Group Name
            pageDetails.Discard();

            nameTypeGroupPicklist.OpenPickList(string.Empty);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.GroupName.SendKeys(NameTypeGroupDbSetup.ExistingNameTypeGroup);
            pageDetails.DefaultsTopic.NameTypePicklist.EnterAndSelect("Instructor");
            pageDetails.Save();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "groupName").HasError, "Group Name should be unique");
            #endregion

            #region Discard Cancel Dialog
            var popup = new CommonPopups(driver);
            nameTypeGroupPicklist.Close();
            popup.DiscardChangesModal.Discard();

            pageDetails.Discard();
            nameTypeGroupPicklist.OpenPickList(string.Empty);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.GroupName.SendKeys("J");
            pageDetails.DefaultsTopic.NameTypePicklist.EnterAndSelect("Instructor");
            pageDetails.Discard();
           
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.GroupName.GetAttribute("value"), "J", "Group Name is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("groupName")));
            #endregion

            #region Update Group Name Type
            pageDetails.Discard();
            nameTypeGroupPicklist.OpenPickList(NameTypeGroupDbSetup.NameTypeGroupToBeAdded);
            nameTypeGroupPicklist.EditRow(0);

            Assert.IsTrue(pageDetails.DefaultsTopic.NavigationBar(driver).Displayed, "Ensure Navigation Bar is visible");
            Assert.AreEqual(NameTypeGroupDbSetup.NameTypeGroupToBeAdded, pageDetails.DefaultsTopic.GroupName.GetAttribute("value"), "Ensure Group Name is equal");

            var editedName = NameTypeGroupDbSetup.ExistingNameTypeGroup + " edited";
            pageDetails.DefaultsTopic.GroupName.Clear();
            pageDetails.DefaultsTopic.GroupName.SendKeys(editedName);
            pageDetails.DefaultsTopic.NameTypePicklist.Clear();
            pageDetails.DefaultsTopic.NameTypePicklist.EnterAndSelect("Owner");
            pageDetails.Save();
            pageDetails.Discard();

            nameTypeGroupPicklist.SearchFor(editedName);

            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
            #endregion

            #region Delete Name Type Group and Click No on Confirmation
            pageDetails.Discard();
            nameTypeGroupPicklist.OpenPickList(NameTypeGroupDbSetup.ExistingNameTypeGroup2);
            nameTypeGroupPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();
            nameTypeGroupPicklist.SearchFor(NameTypeGroupDbSetup.ExistingNameTypeGroup2);

            Assert.AreEqual(1, searchResults.Rows.Count, "Name Type Group value should not get deleted");
            #endregion

            #region Delete Name Type Group
            pageDetails.Discard();
            nameTypeGroupPicklist.OpenPickList(NameTypeGroupDbSetup.ExistingNameTypeGroup2);
            nameTypeGroupPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            nameTypeGroupPicklist.SearchFor(NameTypeGroupDbSetup.ExistingNameTypeGroup2);

            Assert.AreEqual(0, searchResults.Rows.Count, "Name Type Group should get deleted");
            #endregion

            #region Copy Name Type Group Details form Picklist
            pageDetails.Discard();
            nameTypeGroupPicklist.OpenPickList(NameTypeGroupDbSetup.ExistingNameTypeGroup);
            nameTypeGroupPicklist.DuplicateRow(0);

            Assert.AreEqual(NameTypeGroupDbSetup.ExistingNameTypeGroup, pageDetails.DefaultsTopic.GroupName.GetAttribute("value"), "Ensure Group Name is same");
            Assert.IsNull(pageDetails.DefaultsTopic.GroupName.GetAttribute("disabled"), "Ensure Group Name is enabled");
            Assert.Throws<NoSuchElementException>(() => pageDetails.DefaultsTopic.NavigationBar(driver), "Ensure Navigation Bar is not visible");

            pageDetails.DefaultsTopic.GroupName.Clear();
            pageDetails.DefaultsTopic.GroupName.SendKeys(NameTypeGroupDbSetup.NameTypeGroupToBeAdded);
            pageDetails.DefaultsTopic.NameTypePicklist.EnterAndSelect("Owner");

            pageDetails.Save();
            nameTypeGroupPicklist.SearchFor(NameTypeGroupDbSetup.NameTypeGroupToBeAdded);

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameTypeGroupDbSetup.NameTypeGroupToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");

            #endregion
        }
    }
}
