using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.SiteControls
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SiteControls : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SiteControlSearchAndEdit(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var componentEntity = new Component {ComponentName = Fixture.Prefix("Component")};
                componentEntity.InternalName = componentEntity.ComponentName;

                var component = setup.InsertWithNewId(componentEntity);
                var tag1 = setup.InsertWithNewId(new Tag { TagName = Fixture.Prefix("Tag 1") });
                var tag2 = setup.InsertWithNewId(new Tag { TagName = Fixture.Prefix("Tag 2") });
                var releaseVersion = setup.InsertWithNewId(new ReleaseVersion { ReleaseDate = DateTime.Today, VersionName = Fixture.Prefix("Version") });

                var siteControl = setup.InsertWithNewId(new SiteControl
                {
                    DataType = "I",
                    SiteControlDescription = Fixture.String(200),
                    IntegerValue = -4523,
                    VersionId = releaseVersion.Id,
                    Notes = Fixture.String(100),
                    Tags = new List<Tag> { tag1 },
                    Components = new List<Component> { component }
                });

                var searchText = siteControl.ControlId;
                var siteControlMatchingDescription = setup.InsertWithNewId(new SiteControl
                {
                    DataType = "B",
                    SiteControlDescription = searchText
                });

                var siteControlMatchingValue = setup.InsertWithNewId(new SiteControl
                {
                    DataType = "C",
                    StringValue = searchText
                });

                return new
                {
                    SearchText = searchText,
                    Description = siteControl.SiteControlDescription,
                    Value = siteControl.IntegerValue,
                    component.ComponentName,
                    VersionId = releaseVersion.Id,
                    releaseVersion.VersionName,
                    ExistingTag = tag1.TagName,
                    NewTag = tag2.TagName,
                    siteControl.Notes,
                    SiteControlMatchingDescription = siteControlMatchingDescription.ControlId,
                    SiteControlMatchingValue = siteControlMatchingValue.ControlId
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/sitecontrols");
            var siteControls = new SiteControlsPageObjects(driver);
            var actions = new Actions(driver);

            siteControls.SearchField.Clear();
            siteControls.SearchOptions.SearchButton.TryClick();
            siteControls.SummaryGrid.Cell(0, 1).Click();
            actions.SendKeys(Keys.PageDown).Perform();

            var currentPage = driver.FindElement(By.CssSelector("div.k-grid-pager ul.k-pager-numbers li span.k-state-selected"));
            Assert.AreEqual("2", currentPage.Text, "Ensure that we can navigate using shortcuts");

            siteControls.SearchField.Input(data.SearchText);
            Assert.True(siteControls.SearchByName.IsChecked, "Search By Name is the default");

            #region search by description
            siteControls.SearchByDescription.Click();
            siteControls.SearchByName.Click(); // turn off
            siteControls.SearchOptions.SearchButton.TryClick();
            Assert.AreEqual(1, siteControls.SummaryGrid.Rows.Count);
            Assert.AreEqual(data.SearchText, siteControls.SummaryGrid.CellText(0, "Description"), "Search returns record matching description");
            #endregion

            #region search by value
            siteControls.SearchByValue.Click(); 
            siteControls.SearchByDescription.Click(); // turn off
            siteControls.SearchOptions.SearchButton.TryClick();
            Assert.AreEqual(1, siteControls.SummaryGrid.Rows.Count);
            Assert.AreEqual(data.SearchText, siteControls.SummaryGrid.CellText(0, "Value"), "Search returns record matching value");
            #endregion

            #region search by name
            siteControls.SearchByName.Click();
            siteControls.Components.SelectItem(data.ComponentName);
            siteControls.FromRelease.SelectByValue(data.VersionId.ToString());
            siteControls.Tags.SelectItem(data.ExistingTag);
            siteControls.SearchOptions.SearchButton.TryClick();

            Assert.AreEqual(1, siteControls.SummaryGrid.Rows.Count);
            Assert.AreEqual(data.SearchText, siteControls.SummaryGrid.CellText(0, "Name"), "Search returns record matching name");
            Assert.AreEqual(data.VersionName, siteControls.SummaryGrid.CellText(0, "Release"), "Search filtered by release");
            Assert.AreEqual(data.ComponentName, siteControls.SummaryGrid.CellText(0, "Components"), "Search filtered by component");
            Assert.AreEqual(data.Value.ToString(), siteControls.SummaryGrid.CellText(0, "Value"), "Correct data");
            Assert.AreEqual(data.Description, siteControls.SummaryGrid.CellText(0, "Description"), "Correct data");
            #endregion

            #region Expand Row
            siteControls.SummaryGrid.ExpandRow(0);
            var detailRow = siteControls.SummaryGrid.SummaryDetail(0);
            Assert.AreEqual("-4523", detailRow.SettingValue.Value, "Correct data");
            Assert.AreEqual(data.ExistingTag, detailRow.GetTags(), "Search filtered by tag");
            Assert.AreEqual(data.Notes, detailRow.Notes.Value, "Correct data");
            #endregion

            #region Update Site Control
            detailRow.SettingValue.Clear();
            detailRow.SettingValue.Input("abc");
            Assert.True(detailRow.HasError(), "Validation - integer field does not allow letters");

            detailRow.SettingValue.Clear();
            detailRow.SettingValue.Input("-1234");
            detailRow.AddTag(data.NewTag);
            var newNotes = Fixture.String(50);
            detailRow.Notes.Clear();
            detailRow.Notes.Input(newNotes);

            siteControls.Save();
            Assert.NotNull(new CommonPopups(driver).FlashAlert(), "Save Successful!");

            siteControls.SearchOptions.SearchButton.TryClick();
            siteControls.SummaryGrid.ExpandRow(0);
            detailRow = siteControls.SummaryGrid.SummaryDetail(0);
            Assert.AreEqual("-1234", detailRow.SettingValue.Value, "Updated data");
            Assert.True(detailRow.GetTags().Contains(data.NewTag), "Updated data");
            Assert.AreEqual(newNotes, detailRow.Notes.Value, "Updated data");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SiteControlsDetailShouldBeReadonlyWithSecurityRight(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var loginUser = new Users()
                .WithPermission(ApplicationTask.MaintainSiteControl, Allow.Execute | Allow.Modify)
                .Create();

            SignIn(driver, "/#/configuration/general/sitecontrols", loginUser.Username, loginUser.Password);
            var siteControls = new SiteControlsPageObjects(driver);

            siteControls.SearchOptions.SearchButton.Click();
            siteControls.SummaryGrid.ExpandRow(0);
            var summaryDetail = siteControls.SummaryGrid.SummaryDetail(0);

            Assert.IsTrue(summaryDetail.SettingValue.Element.Enabled);
            Assert.IsNull(summaryDetail.Tags.GetAttribute("disabled"));
            Assert.IsTrue(summaryDetail.Notes.Element.Enabled);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SiteControlsDetailShouldBeReadonlyWithNoSecurityRight(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var loginUser = new Users()
                .WithPermission(ApplicationTask.MaintainSiteControl)
                .WithPermission(ApplicationTask.MaintainSiteControl, Deny.Modify)
                .Create();

            SignIn(driver, "/#/configuration/general/sitecontrols", loginUser.Username, loginUser.Password);
            var siteControls = new SiteControlsPageObjects(driver);

            siteControls.SearchOptions.SearchButton.Click();
            siteControls.SummaryGrid.ExpandRow(0);
            var summaryDetail = siteControls.SummaryGrid.SummaryDetail(0);

            Assert.IsFalse(summaryDetail.SettingValue.Element.Enabled);
            Assert.NotNull(summaryDetail.Tags.GetAttribute("disabled"));
            Assert.IsFalse(summaryDetail.Notes.Element.Enabled);
        }
    }
}