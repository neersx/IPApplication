using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Items;
using InprotechKaizen.Model.Persistence;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Search
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ConfigurableItemsFacts : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ConfigurableItemsSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var loginUser = new Users().Create();
            var data = DbSetup.Do(setup =>
            {
                var componentEntity = new Component { ComponentName = Fixture.Prefix("Component") };
                componentEntity.InternalName = componentEntity.ComponentName;

                var component = setup.InsertWithNewId(componentEntity);
                var tag1 = setup.InsertWithNewId(new Tag { TagName = Fixture.Prefix("Tag 1") });
                var tag2 = setup.InsertWithNewId(new Tag { TagName = Fixture.Prefix("Tag 2") });

                var configurationItem = setup.InsertWithNewId(new ConfigurationItem
                {
                    TaskId = (int)ApplicationTask.ChangeMyPassword,
                    Title = Fixture.String(20),
                    Description = Fixture.String(200),
                    Tags = new List<Tag> { tag1 },
                    Components = new List<Component> { component }
                });

                return new
                {
                    SearchTextForTitle = configurationItem.Title,
                    SearchTextForDescription = configurationItem.Description,
                    component.ComponentName,
                    ExistingTag = tag1.TagName,
                    NewTag = tag2.TagName
                };
            });

            SignIn(driver, "/#/configuration/search", loginUser.Username, loginUser.Password);

            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.SearchOptions.SearchButton.Click();

                DbSetup.Do(x =>
                {
                    var db = x.DbContext;
                    // this is not considering grouped item but should be fine given e2e-ken is not normally granted with grouped items
                    var numberOfConfigRows = (from n in db.PermissionsGranted(loginUser.Id, "TASK", null, null, DateTime.Today)
                                              where n.CanDelete || n.CanExecute || n.CanInsert || n.CanUpdate
                                              join c in db.Set<ConfigurationItem>() on new { taskId = n.ObjectIntegerKey } equals new { taskId = (int)c.TaskId } into c1
                                              from c in c1
                                              select c.GroupId).ToList().GroupBy(y => y).SelectMany(group => group.Key == null ? group.ToList() : group.Take(1).ToList()).Count();
                    Assert.AreEqual(numberOfConfigRows, page.ConfigurationItems.Rows.Count(), $"Should have {numberOfConfigRows} rows returned as is permitted for the user.");
                });
            });

            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.SearchField.Input(data.SearchTextForTitle);

                page.SearchOptions.SearchButton.Click();

                Assert.AreEqual(1, page.ConfigurationItems.Rows.Count, $"Should match the item by title {data.SearchTextForTitle}");
                Assert.AreEqual(data.SearchTextForTitle, page.ConfigurationItems.CellText(0, "Name"), "Search returns record matching title");

                page.SearchField.Clear();

                page.SearchOptions.SearchButton.Click();
            });

            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.SearchField.Input(data.SearchTextForDescription);

                page.SearchOptions.SearchButton.Click();

                Assert.AreEqual(1, page.ConfigurationItems.Rows.Count, $"Should match the item by description {data.SearchTextForDescription}");
                Assert.AreEqual(data.SearchTextForDescription, page.ConfigurationItems.CellText(0, "Description"), $"Search returns record matching description {data.SearchTextForDescription}");

                page.SearchField.Clear();

                page.SearchOptions.SearchButton.Click();
            });

            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.Components.SelectItem(data.ComponentName);

                page.SearchOptions.SearchButton.Click();

                Assert.AreEqual(1, page.ConfigurationItems.Rows.Count, $"Should match the item by tag {data.SearchTextForDescription}");
                Assert.AreEqual(data.SearchTextForTitle, page.ConfigurationItems.CellText(0, "Name"), $"Search returns record matching tag {data.ComponentName}");

                page.SearchField.Clear();

                page.SearchOptions.SearchButton.Click();
            });

            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.Tags.Click();
                page.Tags.SelectItem(data.ExistingTag);

                page.SearchOptions.SearchButton.Click();

                Assert.AreEqual(1, page.ConfigurationItems.Rows.Count, $"Should match the item by tag {data.ExistingTag}");
                Assert.AreEqual(data.ExistingTag, page.ConfigurationItems.GetTags(0), $"Should match item by tag '{data.ExistingTag}' but got '{page.ConfigurationItems.GetTags(0)}' instead");

                page.ConfigurationItems.OpenEditModal(0);
            });

            driver.With<ConfigurationItemMaintenanceModal>((page, popups) =>
            {
                Assert.AreEqual(data.SearchTextForTitle, page.Name, $"Should match the item name '{data.SearchTextForTitle}' being edited but was '{page.Name}'.");

                Assert.AreEqual(data.SearchTextForDescription, page.Description, $"Should match the item description '{data.SearchTextForDescription}' being edited but was '{page.Description}'.");

                Assert.AreEqual(data.ComponentName, page.Components, $"Should match the item component name '{data.ComponentName}' being edited but was '{page.Components}'.");

                Assert.True(page.Tags.Displayed, "Should display tags pick list");

                Assert.IsNotNull(page.Save.GetAttributeValue<string>("disabled"), "Should have a disabled Save button");

                Assert.IsNull(page.Discard.GetAttributeValue<string>("disabled"), "Should have an enabled Discard button");

                page.Tags.Click();

                page.Tags.SelectItem(data.NewTag);

                page.Discard.Click();

                popups.DiscardChangesModal.Discard();
            });

            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.SearchOptions.SearchButton.Click();

                Assert.AreEqual(data.ExistingTag, page.ConfigurationItems.GetTags(0), "Should not save because end user discard changes.");

                page.ConfigurationItems.OpenEditModal(0);
            });

            driver.With<ConfigurationItemMaintenanceModal>((page, popups) =>
            {
                Assert.IsNotNull(page.Save.GetAttributeValue<string>("disabled"), "Should have a disabled Save button after discard.");

                page.Tags.SelectItem(data.NewTag);

                page.Save.Click();

                page.Discard.Click(); /* to close */
            });

            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.SearchOptions.SearchButton.Click();

                var tagsUpdatedInCell = page.ConfigurationItems.GetTags(0);

                CollectionAssert.AreEquivalent(new[] { data.ExistingTag, data.NewTag }, tagsUpdatedInCell.Split(',').Select(_ => _.Trim()), $"Should display new tags '{tagsUpdatedInCell}', containing '{data.NewTag}' and '{data.ExistingTag}'");
            });
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class ConfigurableItemsPriorToRelease13 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ConfigurableItemsLinkForOlderInprotech(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var loginUser = new Users().WithPermission(ApplicationTask.AdvancedNameSearch).Create();
            var data = DbSetup.Do(setup =>
            {
                var componentEntity = new Component { ComponentName = Fixture.Prefix("Component") };
                componentEntity.InternalName = componentEntity.ComponentName;

                var component = setup.InsertWithNewId(componentEntity);
                var tag1 = setup.InsertWithNewId(new Tag { TagName = Fixture.Prefix("Tag 1") });

                var leagacyConfig = setup.InsertWithNewId(new ConfigurationItem
                {
                    TaskId = (int)ApplicationTask.ChangeMyPassword,
                    Title = Fixture.String(20),
                    Description = Fixture.String(200),
                    Tags = new List<Tag> { tag1 },
                    Components = new List<Component> { component }
                });

                var appsConfig = setup.InsertWithNewId(new ConfigurationItem
                {
                    TaskId = (int)ApplicationTask.AdvancedNameSearch,
                    Title = Fixture.Prefix("apps"),
                    Description = Fixture.String(200),
                    Tags = new List<Tag> { tag1 },
                    Components = new List<Component> { component },
                    Url = "/apps/#/configuration/search"
                });

                return new
                {
                    legacyTitle = leagacyConfig.Title,
                    appsTitle = appsConfig.Title,
                    component.ComponentName,
                    ExistingTag = tag1.TagName,
                };
            });

            SignIn(driver, "/#/configuration/search", loginUser.Username, loginUser.Password);

            int rowNo;
            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.Tags.Click();
                page.Tags.SelectItem(data.ExistingTag);

                page.SearchOptions.SearchButton.Click();
                Assert.AreEqual(2, page.ConfigurationItems.Rows.Count, $"Should match the item by tag {data.ExistingTag}");

                page.ConfigurationItems.FindRow("Name", data.legacyTitle, out rowNo);

                var warningIcon = page.ConfigurationItems.Cell(rowNo, ConfigurationItemsGrid.ColumnIndex.Icon).FindElements(By.CssSelector(".cpa-icon-exclamation-circle"));

                Assert.True(warningIcon.Count > 0, $"Legacy  icon shown for record {data.legacyTitle}");
                Assert.Contains(warningIcon.First().GetCssValue("color"), new[] { "rgba(255, 0, 0, 1)", "rgb(255, 0, 0)" }, $"Legacy icon shown for record {data.legacyTitle}");

                page.ConfigurationItems.FindRow("Name", data.appsTitle, out rowNo);
                Assert.True(page.ConfigurationItems.Cell(rowNo, ConfigurationItemsGrid.ColumnIndex.Icon).FindElements(By.CssSelector(".cpa-icon-exclamation-circle")).Count == 0, $"Search returns record matching tag {data.ExistingTag}");
            });
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "13.0")]
    public class ConfigurableItemsAfterRelease13 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ConfigurableItemsLinkForOlderInprotech(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var loginUser = new Users().WithPermission(ApplicationTask.AdvancedNameSearch).Create();
            var data = DbSetup.Do(setup =>
            {
                var componentEntity = new Component { ComponentName = Fixture.Prefix("Component") };
                componentEntity.InternalName = componentEntity.ComponentName;

                var component = setup.InsertWithNewId(componentEntity);
                var tag1 = setup.InsertWithNewId(new Tag { TagName = Fixture.Prefix("Tag 1") });

                var leagacyConfig = setup.InsertWithNewId(new ConfigurationItem
                {
                    TaskId = (int)ApplicationTask.ChangeMyPassword,
                    Title = Fixture.String(20),
                    Description = Fixture.String(200),
                    Tags = new List<Tag> { tag1 },
                    Components = new List<Component> { component }
                });

                var appsConfig = setup.InsertWithNewId(new ConfigurationItem
                {
                    TaskId = (int)ApplicationTask.AdvancedNameSearch,
                    Title = Fixture.Prefix("apps"),
                    Description = Fixture.String(200),
                    Tags = new List<Tag> { tag1 },
                    Components = new List<Component> { component },
                    Url = "/apps/#/configuration/search"

                });

                return new
                {
                    legacyTitle = leagacyConfig.Title,
                    appsTitle = appsConfig.Title,
                    component.ComponentName,
                    ExistingTag = tag1.TagName,
                };
            });

            SignIn(driver, "/#/configuration/search", loginUser.Username, loginUser.Password);

            int rowNo;
            driver.With<ConfigurationSearchPageObject>(page =>
            {
                page.Tags.Click();
                page.Tags.SelectItem(data.ExistingTag);

                page.SearchOptions.SearchButton.Click();
                Assert.AreEqual(2, page.ConfigurationItems.Rows.Count, $"Should match the item by tag {data.ExistingTag}");

                page.ConfigurationItems.FindRow("Name", data.legacyTitle, out rowNo);

                var icons = page.ConfigurationItems.Cell(rowNo, ConfigurationItemsGrid.ColumnIndex.Icon).FindElements(By.CssSelector(".cpa-icon-exclamation-circle"));
                if (browserType == BrowserType.Ie)
                {
                    Assert.AreEqual(0, icons.Count, $"Legacy  icon shown for record {data.legacyTitle}");
                }
                else
                {
                    Assert.Greater(icons.Count, 0, $"Legacy  icon shown for record {data.legacyTitle}");
                    Assert.Contains(icons.First().GetCssValue("color"), new[] { "rgba(144, 144, 144, 1)", "rgb(144, 144, 144)" }, $"Legacy  icon shown for record {data.legacyTitle}");
                }

                page.ConfigurationItems.FindRow("Name", data.appsTitle, out rowNo);
                Assert.True(page.ConfigurationItems.Cell(rowNo, ConfigurationItemsGrid.ColumnIndex.Icon).FindElements(By.CssSelector(".cpa-icon-exclamation-circle")).Count == 0, $"Search returns record matching tag {data.ExistingTag}");
            });
        }
    }
}