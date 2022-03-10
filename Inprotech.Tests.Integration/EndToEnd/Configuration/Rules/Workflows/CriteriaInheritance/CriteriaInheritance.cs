using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaInheritance
{
    [TestFixture]
    public class CriteriaInheritance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void InheritanceTreeView(BrowserType browserType)
        {
            CriteriaInheritanceDbSetup.DataFixture dataFixture;
            using (var db = new SqlDbContext())
            {
                dataFixture = new CriteriaInheritanceDbSetup(db).SetUp();
            }

            var driver = BrowserProvider.Get(browserType);

            NavigateToPage(driver, dataFixture.ChildId, dataFixture.AnotherId);

            var page = new CriteriaInheritancePage(driver);

            Assert.True(page.PageTitle().Contains("Inheritance"));
            Assert.True(driver.Url.Contains("?criteriaIds="));
            Assert.True(driver.Url.Contains(dataFixture.AnotherId));
            Assert.True(driver.Url.Contains(dataFixture.ChildId));

            var nodes = page.GetAllTreeNodes();

            Assert.AreEqual(4, nodes.Length);

            Assert.True(page.Detail.CriteriaHeader.Contains(nodes[1].CriteriaId), "First from search selected by default");
            Assert.True(page.Detail.CriteriaHeader.Contains(nodes[1].CriteriaName));

            Assert.AreEqual(dataFixture.ParentId, nodes[0].CriteriaId);
            Assert.AreEqual(dataFixture.ParentName, nodes[0].CriteriaName);
            Assert.IsTrue(nodes[0].Url.EndsWith("#/configuration/rules/workflows/" + nodes[0].CriteriaId));
            Assert.IsFalse(nodes[0].IsInSearch);
            Assert.IsTrue(nodes[0].IsVisible);
            Assert.IsTrue(nodes[0].IsProtected);

            Assert.AreEqual(dataFixture.ChildId, nodes[1].CriteriaId);
            Assert.AreEqual(dataFixture.ChildName, nodes[1].CriteriaName);
            Assert.IsTrue(nodes[1].IsInSearch);
            Assert.IsTrue(nodes[1].IsVisible);
            Assert.IsFalse(nodes[1].IsProtected);

            Assert.AreEqual(dataFixture.GrandChildId, nodes[2].CriteriaId);
            Assert.AreEqual(dataFixture.GrandChildName, nodes[2].CriteriaName);

            Assert.AreEqual(dataFixture.AnotherId, nodes[3].CriteriaId);
            Assert.AreEqual(dataFixture.AnotherName, nodes[3].CriteriaName);

            Assert.IsFalse(page.IsExpandAllButtonEnabled);
            Assert.IsTrue(page.IsCollapseAllButtonEnabled);

            page.SelectNodeByIndex(0);
            Assert.False(page.BreakInheritanceButton.Enabled);

            page.SelectNodeByIndex(2);
            page.BreakInheritanceButton.TryClick();
            page.UnlinkModal.Proceed();
            nodes = page.GetAllTreeNodes();

            Assert.AreEqual(dataFixture.GrandChildId, nodes[0].CriteriaId);
            Assert.AreEqual(dataFixture.ParentId, nodes[1].CriteriaId);
            Assert.AreEqual(dataFixture.ChildId, nodes[2].CriteriaId);
            Assert.AreEqual(dataFixture.AnotherId, nodes[3].CriteriaId);

            page.CollapseAll();

            Assert.IsTrue(nodes[0].IsVisible, "grandchild is visible");
            Assert.IsTrue(nodes[1].IsVisible, "parent is visible");
            Assert.IsFalse(nodes[2].IsVisible, "child is collapsed");
            Assert.IsTrue(nodes[3].IsVisible, "another is visible");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CriteriaDetailView(BrowserType browserType)
        {
            CriteriaInheritanceDbSetup.DetailDataFixture dataFixture;
            using (var db = new SqlDbContext())
            {
                dataFixture = new CriteriaInheritanceDbSetup(db).SetUpDetail();
            }

            var driver = BrowserProvider.Get(browserType);

            NavigateToPage(driver, dataFixture.CriteriaId);

            var page = new CriteriaInheritancePage(driver);

            page.SelectNodeByIndex(0);

            Assert.True(page.Detail.CriteriaHeader.Contains(dataFixture.CriteriaId));
            Assert.True(page.Detail.CriteriaHeader.Contains(dataFixture.CriteriaName));
            Assert.AreEqual(dataFixture.Office, page.Detail.Office);
            Assert.AreEqual(dataFixture.CaseType, page.Detail.CaseType);
            Assert.AreEqual(dataFixture.Jurisdiction, page.Detail.Jurisdiction);
            Assert.AreEqual(dataFixture.PropertyType, page.Detail.PropertyType);
            Assert.AreEqual(dataFixture.Action, page.Detail.Action);
            Assert.AreEqual(dataFixture.CaseCategory, page.Detail.CaseCategory);
            Assert.AreEqual(dataFixture.SubType, page.Detail.SubType);
            Assert.AreEqual(dataFixture.LocalOrForeign, page.Detail.LocalOrForeign);
            Assert.AreEqual(dataFixture.InUse, page.Detail.InUse);
            Assert.AreEqual(dataFixture.Protected, page.Detail.Protected);
        }

        void NavigateToPage(NgWebDriver driver, params string[] criteriaIds)
        {
            SignIn(driver, "/#/configuration/rules/workflows");

            driver.FindRadio("search-by-criteria").Click();
            var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");

            foreach (var c in criteriaIds)
            {
                pl.EnterAndSelect(c);
            }

            var searchOptions = new SearchOptions(driver);
            searchOptions.SearchButton.ClickWithTimeout();

            driver.WaitForAngular();

            var actionMenu = new ActionMenu(driver, "workflowSearch");
            actionMenu.OpenOrClose();
            actionMenu.SelectPage();
            actionMenu.Option("viewInheritance").WithJs().Click(); // Have to click with Js here. ClickWithTimeout causes the menu to close in firefox.
        }
        
        [TestFixture]
        public class Manage : IntegrationTest
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.FireFox)]
            public void ChangeCriteriaParentageByDragAndDrop(BrowserType browserType)
            {
                Criteria criteria1, criteria2;

                using (var setup = new DbSetup())
                {
                    criteria1 = setup.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("criteria1"),
                        PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                        UserDefinedRule = 0
                    });

                    criteria2 = setup.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("criteria2"),
                        PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                        UserDefinedRule = 1
                    });

                    var caseId = new CaseBuilder(setup.DbContext).Create(Fixture.Prefix()).Id;
                    var action = setup.InsertWithNewId(new Action { Name = Fixture.Prefix("action") });
                    setup.Insert(new OpenAction
                    {
                        CaseId = caseId,
                        Action = action,
                        Criteria = criteria2
                    });
                }

                var driver = BrowserProvider.Get(browserType);
                SignIn(driver, $"/#/configuration/rules/workflows/inheritance?criteriaIds={criteria1.Id},{criteria2.Id}");

                var page = new CriteriaInheritancePage(driver);
                page.MoveNodeOver(0, 1);
                var modal = new AlertModal(driver);
                modal.Ok();

                page.MoveNodeOver(1, 0);

                page.ClickProceedButtonInModal();

                driver.WaitForBlockUi();

                page.ClickConfirmButtonInModal();

                var nodes = page.GetAllTreeNodes();

                Assert.AreEqual(criteria1.Id.ToString(), nodes[0].CriteriaId);
                Assert.IsTrue(nodes[0].IsParent);
                Assert.AreEqual(criteria2.Id.ToString(), nodes[1].CriteriaId);
                Assert.IsFalse(nodes[1].IsParent);
            }

            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.FireFox)]
            public void ShouldNotChangeParentageWithoutPermission(BrowserType browserType)
            {
                //todo: cover deleting and breaking inheritance
                Criteria child, parent, parentSibling;

                using (var setup = new DbSetup())
                {
                    parentSibling = setup.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("parentA"),
                        PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                        UserDefinedRule = 1
                    });

                    child = setup.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("child"),
                        PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                        UserDefinedRule = 0
                    });

                    parent = setup.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("parentB"),
                        PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                        UserDefinedRule = 1
                    });

                    setup.Insert(new Inherits
                    {
                        Criteria = child,
                        FromCriteria = parent
                    });
                }

                var driver = BrowserProvider.Get(browserType);
                var user = new Users()
                           .WithPermission(ApplicationTask.MaintainWorkflowRules)
                           .WithPermission(ApplicationTask.MaintainWorkflowRulesProtected, Deny.Execute)
                           .Create();

                SignIn(driver, $"/#/configuration/rules/workflows/inheritance?criteriaIds={parent.Id},{parentSibling.Id}", user.Username, user.Password);

                var page = new CriteriaInheritancePage(driver);
                var commonPopups = new CommonPopups(driver);

                // move criteria with protected child
                page.MoveNodeOver(1, 0);

                commonPopups.AlertModal.Ok();

                var nodes = page.GetAllTreeNodes();
                Assert.AreEqual(parentSibling.Id.ToString(), nodes[0].CriteriaId, "criteria has not moved");
                Assert.IsFalse(nodes[0].IsParent, "criteria has not moved to child level");
                Assert.AreEqual(parent.Id.ToString(), nodes[1].CriteriaId);
                Assert.AreEqual(child.Id.ToString(), nodes[2].CriteriaId);

                // move protected criteria
                page.MoveNodeOver(2, 0);

                commonPopups.AlertModal.Ok();

                nodes = page.GetAllTreeNodes();
                Assert.AreEqual(parentSibling.Id.ToString(), nodes[0].CriteriaId, "criteria has not moved");
                Assert.IsFalse(nodes[0].IsParent, "criteria has not moved to child level");
                Assert.AreEqual(parent.Id.ToString(), nodes[1].CriteriaId);
                Assert.AreEqual(child.Id.ToString(), nodes[2].CriteriaId);
            }

            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void DeletesCriteriaAndBreaksInheritanceForChildren(BrowserType browserType)
            {
                var data = DbSetup.Do(setup =>
                           {
                               var first = setup.InsertWithNewId(new Criteria
                               {
                                   Description = Fixture.Prefix("1"),
                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                               });

                               var parent = setup.InsertWithNewId(new Criteria
                               {
                                   Description = Fixture.Prefix("2"),
                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                               });

                               var child = setup.InsertWithNewId(new Criteria
                               {
                                   Description = Fixture.Prefix("3"),
                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                               });

                               var grandchild = setup.InsertWithNewId(new Criteria
                               {
                                   Description = Fixture.Prefix("4"),
                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                               });

                               setup.Insert(new Inherits
                               {
                                   Criteria = grandchild,
                                   FromCriteria = child
                               });

                               setup.Insert(new Inherits
                               {
                                   Criteria = child,
                                   FromCriteria = parent
                               });

                               new OpenActionBuilder(setup.DbContext).WithCriteria(parent).CreateInDb();

                               return new
                               {
                                   ParentSiblingId = first.Id.ToString(),
                                   ParentId = parent.Id.ToString(),
                                   ChildId = child.Id.ToString(),
                                   GrandchildId = grandchild.Id.ToString()
                               };
                           });

                var driver = BrowserProvider.Get(browserType);
                SignIn(driver, $"/#/configuration/rules/workflows/inheritance?criteriaIds={data.ParentId},{data.ParentSiblingId}");

                var page = new CriteriaInheritancePage(driver);
                var commonPopups = new CommonPopups(driver);

                // unable to delete parent criteria which is used by case
                page.SelectNodeByIndex(1);
                page.ClickDeleteButton();

                page.UnableToDeleteModal.ClickOkButton();

                // deletes child criteria
                page.SelectNodeByIndex(2);
                page.ClickDeleteButton();

                commonPopups.ConfirmDeleteModal.Delete().ClickWithTimeout();

                var nodes = page.GetAllTreeNodes().ToArray();

                Assert.AreEqual(3, nodes.Length, "child node is deleted");
                Assert.AreEqual(data.ParentSiblingId, nodes[0].CriteriaId);
                Assert.AreEqual(data.GrandchildId, nodes[1].CriteriaId, "grandchild node has moved above parent node");
                Assert.AreEqual(data.ParentId, nodes[2].CriteriaId);
            }
        }
    }
}