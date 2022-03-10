using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.DataItemGroup
{
    [Category(Categories.E2E)]
    [TestFixture]
    class DataItemGroupPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dataItemGroupDbSetup = new DataItemGroupDbSetup();
            _dataItemGroupDbSetup.Prepare();
        }

        DataItemGroupDbSetup _dataItemGroupDbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddDataItemGroupDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/dataitems");

            var dataItemGroupPicklist = new PickList(driver).ById("dataitem-group-picklist");
            var pageDetails = new DataItemGroupDetailPage(driver);

            dataItemGroupPicklist.OpenPickList(string.Empty);

            #region Add Data Item Group
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.DescriptionTextBox(driver).SendKeys("12345678901234567890123456789012345678901234567890");
            Assert.IsTrue(new TextField(driver, "description").HasError, "Description should not be more than 40 characters");
            pageDetails.DefaultsTopic.DescriptionTextBox(driver).Clear();
            pageDetails.Save();
            Assert.IsTrue(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"), "Ensure Save is disabled");
            pageDetails.DefaultsTopic.DescriptionTextBox(driver).SendKeys(DataItemGroupDbSetup.DataItemGroupToBeAdded);
            pageDetails.Save();

            pageDetails.DefaultsTopic.ClearButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(DataItemGroupDbSetup.DataItemGroupToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(DataItemGroupDbSetup.DataItemGroupToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            #endregion

            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.DescriptionTextBox(driver).SendKeys(DataItemGroupDbSetup.ExistingDataItemGroup);
            pageDetails.Save();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            pageDetails.Discard();
            popups.DiscardChangesModal.Discard();

            #region Update Data Item Group Name
            pageDetails.DefaultsTopic.ClearButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(DataItemGroupDbSetup.ExistingDataItemGroup2);
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            dataItemGroupPicklist.EditRow(0);

            Assert.AreEqual(DataItemGroupDbSetup.ExistingDataItemGroup2, pageDetails.DefaultsTopic.DescriptionTextBox(driver).GetAttribute("value"), "Ensure Data Item Group Name is equal");

            var editedName = DataItemGroupDbSetup.ExistingDataItemGroup2 + " edited";
            pageDetails.DefaultsTopic.DescriptionTextBox(driver).Clear();
            pageDetails.DefaultsTopic.DescriptionTextBox(driver).SendKeys(editedName);
            pageDetails.Save();

            pageDetails.DefaultsTopic.ClearButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(editedName);
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
            #endregion

            #region Unable to Delete Data Item Group as in use
            pageDetails.DefaultsTopic.ClearButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("e2e-delete");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            dataItemGroupPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            popups.AlertModal.Ok();
            pageDetails.DefaultsTopic.ClearButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("e2e-delete");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            Assert.AreEqual(1, searchResults.Rows.Count, "Data Item Group value should not get deleted");
            #endregion

            pageDetails.DefaultsTopic.ClearButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(DataItemGroupDbSetup.ExistingDataItemGroup3);
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            dataItemGroupPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            pageDetails.DefaultsTopic.ClearButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(DataItemGroupDbSetup.ExistingDataItemGroup3);
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            Assert.AreEqual(0, searchResults.Rows.Count, "Data Item Group should get deleted");
        }
    }
}
