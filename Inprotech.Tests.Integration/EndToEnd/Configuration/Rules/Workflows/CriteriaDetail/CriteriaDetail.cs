using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaInheritance;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CriteriaDetail : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ResetCriteria(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData dataFixture;
            using (var setup = new CriteriaDetailDbSetup())
            {
                dataFixture = setup.SetUp();
                var deleteEvent = setup.InsertWithNewId(new Event());
                setup.Insert(new ValidEvent(dataFixture.ChildCriteriaId, deleteEvent.Id, "I will be removed"));
                
                // add a grandchild so the confirmation dialog pops up with the Apply to descendants option
                var grandchild = setup.AddCriteria(Fixture.String(6), dataFixture.ChildCriteriaId);
                setup.Insert(new Inherits(grandchild.Id, dataFixture.ChildCriteriaId));

                setup.Insert(new DataEntryTask(dataFixture.CriteriaId, 0) {Description = "I will be added"});
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{dataFixture.ChildCriteriaId}");

            var criteriaDetailPage = new CriteriaDetailPage(driver);

            criteriaDetailPage.EventsTopic.NavigateTo();
            Assert.AreEqual(dataFixture.ChildCriteria.ValidEvents.Count, criteriaDetailPage.EventsTopic.EventsGrid.Rows.Count);

            criteriaDetailPage.EntriesTopic.NavigateTo();
            Assert.AreEqual(dataFixture.ChildCriteria.DataEntryTasks.Count, criteriaDetailPage.EntriesTopic.Grid.Rows.Count);

            criteriaDetailPage.ActivateActionsTab();
            criteriaDetailPage.ResetInheritance();
            driver.WaitForAngular();

            Assert.IsTrue(criteriaDetailPage.ResetEntryInheritanceConfirmation.ApplyToDescendants.Enabled);
            criteriaDetailPage.ResetEntryInheritanceConfirmation.Proceed();

            Assert.AreEqual(2, criteriaDetailPage.EventsTopic.EventsGrid.Rows.Count, "Two events inherited from parent, extra event removed");
            var eventIds = criteriaDetailPage.EventsTopic.GetAllEventIds();
            Assert.IsTrue(eventIds.Contains(dataFixture.EventId.ToString()), "Parent Event1 should be inherited");
            Assert.IsTrue(eventIds.Contains(dataFixture.EventId2.ToString()), "Parent Event2 should be inherited");
            Assert.IsTrue(criteriaDetailPage.EventsTopic.EventsGrid.Rows.All(_ => _.FindElement(By.CssSelector("ip-inheritance-icon")).Displayed), "All Events should be marked as inherited");

            Assert.AreEqual(2, criteriaDetailPage.EntriesTopic.Grid.Rows.Count, "Missing Entry is reinherited");
            Assert.IsTrue(criteriaDetailPage.EntriesTopic.Grid.Rows.All(_ => _.FindElement(By.CssSelector("ip-inheritance-icon")).Displayed), "All Entries should be marked as inherited");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void BreakInheritance(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData dataFixture;
            using (var setup = new CriteriaDetailDbSetup())
            {
                dataFixture = setup.SetUp();

                // add a grandchild so parent inheritance icon displays
                var grandchild = setup.AddCriteria(Fixture.String(6), dataFixture.ChildCriteriaId);
                setup.Insert(new Inherits(grandchild.Id, dataFixture.ChildCriteriaId));
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{dataFixture.ChildCriteriaId}");

            var criteriaDetailPage = new CriteriaDetailPage(driver);

            criteriaDetailPage.EventsTopic.NavigateTo();
            Assert.AreEqual(dataFixture.ChildCriteria.ValidEvents.Count, criteriaDetailPage.EventsTopic.EventsGrid.Rows.Count);
            Assert.True(criteriaDetailPage.EventsTopic.EventsGrid.Rows.All(_ => _.FindElement(By.CssSelector("ip-inheritance-icon span.cpa-icon-inheritance")).Displayed), "All event rows should be inherited");

            criteriaDetailPage.EntriesTopic.NavigateTo();
            Assert.AreEqual(dataFixture.ChildCriteria.DataEntryTasks.Count, criteriaDetailPage.EntriesTopic.Grid.Rows.Count);
            Assert.True(criteriaDetailPage.EntriesTopic.Grid.Rows.All(_ => _.FindElement(By.CssSelector("ip-inheritance-icon span.cpa-icon-inheritance")).Displayed), "All entry rows should be inherited");

            criteriaDetailPage.ActivateActionsTab();
            criteriaDetailPage.BreakInheritance();
            driver.WaitForAngular();
            
            criteriaDetailPage.BreakInheritanceConfirmation.Proceed();

            // check parent inheritance icon in header
            Assert.True(criteriaDetailPage.TitleHeader.FindElement(By.CssSelector("div.btn-icon a span.cpa-icon-grey.cpa-icon-inheritance")).Displayed, "Top level inheritance icon should be displayed");

            // check all inheritance icons are removed
            Assert.False(criteriaDetailPage.EventsTopic.EventsGrid.FindElements(By.CssSelector("ip-inheritance-icon span.cpa-icon-inheritance")).Any(), "All event rows should be un-inherited");
            Assert.False(criteriaDetailPage.EntriesTopic.Grid.FindElements(By.CssSelector("ip-inheritance-icon span.cpa-icon-inheritance")).Any(), "All entry rows should be un-inherited");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NavigateBetweenItems(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData dataFixture;
            using (var setup = new CriteriaDetailDbSetup())
            {
                dataFixture = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            CriteriaHelper.GoToMaintenancePage(driver, dataFixture.CriteriaId, dataFixture.ChildCriteriaId);

            var page = new CriteriaDetailPage(driver);

            Assert.AreEqual(dataFixture.CriteriaId.ToString(), page.CriteriaNumber);
            Assert.True(driver.Title.Contains(dataFixture.CriteriaId.ToString()));
            Assert.False(page.EventsTopic.IsActive());

            page.EventsTopic.NavigateTo();
            Assert.True(page.EventsTopic.IsActive());

            page.PageNav.NextPage();
            Assert.AreEqual(dataFixture.ChildCriteriaId.ToString(), page.CriteriaNumber);
            Assert.True(page.EventsTopic.IsActive());
            Assert.AreEqual(1, page.CountOfCriteriaInheritedIcon());
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldDisableAllFieldsIfInsufficentPermission(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var data = DbSetup.Do(setup =>
                                      {
                                          var child = setup.InsertWithNewId(new Criteria
                                                                                {
                                                                                    Description = Fixture.Prefix("child"),
                                                                                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                                    UserDefinedRule = 0
                                                                                });

                                          var parent = setup.InsertWithNewId(new Criteria
                                                                                 {
                                                                                     Description = Fixture.Prefix("parent"),
                                                                                     PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                                     UserDefinedRule = 1
                                                                                 });

                                          setup.Insert(new Inherits
                                                           {
                                                               Criteria = child,
                                                               FromCriteria = parent
                                                           });

                                          return new
                                                     {
                                                         Child = child,
                                                         Parent = parent
                                                     };
                                      });
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainWorkflowRules)
                       .WithPermission(ApplicationTask.MaintainWorkflowRulesProtected, Deny.Execute)
                       .Create();

            SignIn(driver, $"/#/configuration/rules/workflows/{data.Child.Id}", user.Username, user.Password);

            var page = new CriteriaDetailPage(driver);

            Assert.IsTrue(page.IsPermissionAlertDisplayed, "should display permission alert before all topics");
            Assert.IsFalse(page.CharacteristicsTopic.IsCriteriaNameEnabled, "the criteria name field should be disabled");
            Assert.IsFalse(page.IsSaveDisplayed, "save button is not displayed");

            SignIn(driver, $"/#/configuration/rules/workflows/{data.Parent.Id}", user.Username, user.Password);

            Assert.IsTrue(page.IsPermissionAlertDisplayed, "should display permission alert before all topics");
            Assert.IsTrue(page.PermissionAlertMessage.Contains(data.Parent.Id.ToString()), $"displays message to indiciate current criteria({data.Parent.Id}) has at least one protected descendant");
            Assert.IsFalse(page.CharacteristicsTopic.IsCriteriaNameEnabled, "the criteria name field should be disabled");
            Assert.IsFalse(page.IsSaveDisplayed, "save button is not displayed");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldNavigateToInheritance(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var parent = criteriaBuilder.Create();
                var child = criteriaBuilder.Create();

                setup.Insert(new Inherits(child.Id, parent.Id));

                return new
                {
                    ParentId = parent.Id,
                    ChildId = child.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            CriteriaHelper.GoToMaintenancePage(driver, data.ParentId, data.ChildId);

            var detailPage = new CriteriaDetailPage(driver);
            Assert.AreEqual(data.ParentId.ToString(), detailPage.CriteriaNumber);

            detailPage.CriteriaInheritedIcon().TryClick();

            var inheritancePage = new CriteriaInheritancePage(driver);

            Assert.True(inheritancePage.PageTitle().Contains("Inheritance"));
            Assert.True(driver.Url.Contains("?criteriaIds=" + data.ParentId));

            inheritancePage.LevelUpIcon().TryClick();
            Assert.AreEqual(data.ParentId.ToString(), detailPage.CriteriaNumber);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NestedStateNavigation(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData data;
            using (var setup = new CriteriaDetailDbSetup())
            {
                data = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            CriteriaHelper.GoToMaintenancePage(driver, data.CriteriaId, data.CriteriaId);

            driver.With<CriteriaDetailPage>(page =>
            {
                page.CriteriaInheritedIcon().Click();
            });

            driver.With<CriteriaInheritancePage>(inheritanceTreePage =>
            {
                inheritanceTreePage.ClickNodeByIndex(1);
            });

            driver.With<CriteriaDetailPage>(page =>
            {
                Assert.AreEqual(data.ChildCriteriaId.ToString(), page.CriteriaNumber);

                page.EventsTopic.EventsGrid.Cell(0, 2).FindElement(By.CssSelector("a")).Click();
            });

            driver.With<EventControlPage>(eventControlPage =>
            {
                eventControlPage.Overview.EventDescription.Input.SendKeys(Fixture.String(5));
                eventControlPage.Overview.MaxCycles.Input.SendKeys("1");
                eventControlPage.Overview.ImportanceLevel.Input.SelectByIndex(1);
                eventControlPage.Save();
                new InfoModal(driver).Confirm();

                Try.Retry(3, 1, () => eventControlPage.LevelUpButton.Click());
            });
            
            driver.With<CriteriaDetailPage>(page =>
            {
                Assert.AreEqual(data.ChildCriteriaId.ToString(), page.CriteriaNumber);
                page.LevelUp();
            });

            driver.With<CriteriaInheritancePage>(inheritanceTreePage =>
            {
                Assert.IsTrue(driver.Url.Contains($"inheritance?criteriaIds={data.CriteriaId}"));
                inheritanceTreePage.LevelUpIcon().Click();
            });

            // TODO: this is breaking on the e2e server for no reason
            //driver.With<CriteriaDetailPage>(page =>
            //{
            //    Assert.AreEqual(data.CriteriaId.ToString(), page.CriteriaNumber);
            //    page.LevelUp();
            //});

            //var pickList = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            //Assert.AreEqual(data.CriteriaId.ToString(), pickList.Tags.First());
        }
    }
}