using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Tags
{
    [Category(Categories.E2E)]
    [TestFixture]
    class TagsPicklist : IntegrationTest
    {
        TagsPicklistDbSetup _tagsPicklistDbSetUp;

        [SetUp]
        public void Setup()
        {
            _tagsPicklistDbSetUp = new TagsPicklistDbSetup();
            _tagsPicklistDbSetUp.DataSetUp();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainTagFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/sitecontrols");
            var pageDetails = new TagsDetailPage(driver);

            pageDetails.DefaultsTopic.SearchSiteControl(driver).SendKeys("e2e");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("e2e", searchResults.CellText(0, 1), "Search returns record matching name");

            #region Create two new Tags
            var tagPicklist = new PickList(driver).ByName(string.Empty, "tags");
            tagPicklist.OpenPickList(string.Empty);

            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.TagNameTextBox(driver).SendKeys("e2e - Tag1");
            pageDetails.DefaultsTopic.TagSaveButton(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.TagNameTextBox(driver).SendKeys("e2e - Tag2");
            pageDetails.DefaultsTopic.TagSaveButton(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchTag(driver).SendKeys("e2e");
            pageDetails.DefaultsTopic.SearchButtonTag(driver).TryClick();

            var picklistSearchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(2, picklistSearchResults.Rows.Count);

            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Add Tags in Site Control
            pageDetails.DefaultsTopic.ExpandSiteControl(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SelectTagInSiteControl(driver).SendKeys("e2e - Tag1");
            pageDetails.DefaultsTopic.EnterNotes(driver).SendKeys("e2e");
            pageDetails.DefaultsTopic.SelectTagInSiteControl(driver).SendKeys("e2e - Tag2");
            pageDetails.DefaultsTopic.EnterNotes(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            #endregion

            #region Edit Tags
            tagPicklist.OpenPickList(string.Empty);
            pageDetails.DefaultsTopic.SearchTag(driver).SendKeys("e2e - Tag2");
            pageDetails.DefaultsTopic.SearchButtonTag(driver).WithJs().Click();
            Assert.AreEqual(1, picklistSearchResults.Rows.Count);
            pageDetails.DefaultsTopic.EditIcon(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.TagNameTextBox(driver).Clear();
            pageDetails.DefaultsTopic.TagNameTextBox(driver).SendKeys("e2e - Tag1");
            pageDetails.DefaultsTopic.TagSaveButton(driver).ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.ConfirmModal.Replace().ClickWithTimeout();
            Assert.AreEqual(0, picklistSearchResults.Rows.Count);
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Delete Tags
            tagPicklist.OpenPickList(string.Empty);
            pageDetails.DefaultsTopic.SearchTag(driver).SendKeys("e2e - Tag1");
            pageDetails.DefaultsTopic.SearchButtonTag(driver).WithJs().Click();
            Assert.AreEqual(1, picklistSearchResults.Rows.Count);
            pageDetails.DefaultsTopic.DeleteIcon(driver).ClickWithTimeout();
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            popups.ConfirmModal.Yes().ClickWithTimeout();
            Assert.AreEqual(0, picklistSearchResults.Rows.Count);
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion
        }
    }
}
