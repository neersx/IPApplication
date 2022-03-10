using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Xml.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowInheritanceControllerFacts : FactBase
    {
        public class ParseTreeMethod : FactBase
        {
            [Fact]
            public void ParsesMultipleTrees()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);
                var id1 = 1;
                var name1 = "a";
                var id2 = 2;
                var name2 = "b";
                var xml = $"<INHERITS><CRITERIA><CRITERIANO>{id1}</CRITERIANO><DESCRIPTION>{name1}</DESCRIPTION></CRITERIA><CRITERIA><CRITERIANO>{id2}</CRITERIANO><DESCRIPTION>{name2}</DESCRIPTION></CRITERIA></INHERITS>";
                var totalCount = 0;

                var trees = f.Subject.ParseTrees(XElement.Parse(xml), new[] {1}, out totalCount);

                Assert.Equal(2, trees.Count());
                Assert.Equal(2, totalCount);

                var tree1 = trees.First();
                var tree2 = trees.Last();

                Assert.Equal(id1, tree1.Id);
                Assert.Equal(name1, tree1.Name);
                Assert.Equal(id2, tree2.Id);
                Assert.Equal(name2, tree2.Name);
            }

            [Fact]
            public void ParsesSingleTree()
            {
                var grandchildId = 1;
                var grandchildName = "a";

                var childId = 2;
                var childName = "b";

                var siblingId = 22;
                var siblingName = "bb";

                var parentId = 3;
                var parentName = "c";

                var grandchildXml = $"<CRITERIA>" +
                                    $"<CRITERIANO>{grandchildId}</CRITERIANO>" +
                                    $"<DESCRIPTION>{grandchildName}</DESCRIPTION>" +
                                    $"<ISUSERDEFINED>0</ISUSERDEFINED>" +
                                    $"</CRITERIA>";

                var childXml = $"<CRITERIA>" +
                               $"<CRITERIANO>{childId}</CRITERIANO>" +
                               $"<DESCRIPTION>{childName}</DESCRIPTION>" +
                               $"<ISUSERDEFINED>0</ISUSERDEFINED>" +
                               $"<CHILDCRITERIA>{grandchildXml}</CHILDCRITERIA>" +
                               $"</CRITERIA>";

                var siblingXml = $"<CRITERIA>" +
                                 $"<CRITERIANO>{siblingId}</CRITERIANO>" +
                                 $"<DESCRIPTION>{siblingName}</DESCRIPTION>" +
                                 $"<ISUSERDEFINED>1</ISUSERDEFINED>" +
                                 $"</CRITERIA>";

                var parentXml = $"<CRITERIA>" +
                                $"<CRITERIANO>{parentId}</CRITERIANO>" +
                                $"<DESCRIPTION>{parentName}</DESCRIPTION>" +
                                $"<ISUSERDEFINED>1</ISUSERDEFINED>" +
                                $"<CHILDCRITERIA>{childXml + siblingXml}</CHILDCRITERIA>" +
                                $"</CRITERIA>";

                var f = new WorkflowInheritanceControllerFixture(Db);
                var tree = f.Subject.ParseTree(XElement.Parse(parentXml), new[] {22, 2, 1});

                Assert.Equal(parentId, tree.Id);
                Assert.Equal(parentName, tree.Name);
                Assert.False(tree.IsProtected);
                Assert.Equal(4, tree.TotalCount);
                Assert.False(tree.IsInSearch);
                Assert.Equal(2, tree.Items.Count());
                Assert.False(tree.IsFirstFromSearch);

                var child = tree.Items.First();
                Assert.Equal(childId, child.Id);
                Assert.Equal(childName, child.Name);
                Assert.True(child.IsProtected);
                Assert.True(child.IsInSearch);
                Assert.True(child.IsFirstFromSearch);

                var sibling = tree.Items.Last();
                Assert.Equal(siblingId, sibling.Id);
                Assert.Equal(siblingName, sibling.Name);
                Assert.False(sibling.IsProtected);
                Assert.True(sibling.IsInSearch);
                Assert.False(sibling.IsFirstFromSearch);

                var grandchild = child.Items.Single();
                Assert.Equal(grandchildId, grandchild.Id);
                Assert.Equal(grandchildName, grandchild.Name);
                Assert.True(grandchild.IsProtected);
                Assert.True(grandchild.IsInSearch);
                Assert.False(grandchild.IsFirstFromSearch);

                Assert.False(grandchild.HasProtectedChildren);
                Assert.True(child.HasProtectedChildren);
                Assert.True(tree.HasProtectedChildren);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void IncludesSelectedNodeIfNotInTree()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);

                new Office().In(Db);
                f.WorkflowInheritanceService.GetInheritanceTreeXml(Arg.Is<IEnumerable<int>>(_ => _.First() == 1)).Returns("<INHERITS><CRITERIA><CRITERIANO>1</CRITERIANO></CRITERIA></INHERITS>");
                f.WorkflowInheritanceService.GetInheritanceTreeXml(Arg.Is<IEnumerable<int>>(_ => _.First() == 2)).Returns("<INHERITS><CRITERIA><CRITERIANO>2</CRITERIANO></CRITERIA></INHERITS>");
                f.WorkflowPermissionHelper.CanEditProtected().Returns(true);

                var r = f.Subject.Search("1", 2);

                Assert.Equal(2, r.TotalCount);
                Assert.Equal(2, r.Trees.First().Id);
                Assert.Equal(1, r.Trees.Last().Id);
            }

            [Fact]
            public void ReturnsTreeData()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);

                new Office().In(Db);
                f.WorkflowInheritanceService.GetInheritanceTreeXml(null).ReturnsForAnyArgs("<INHERITS><CRITERIA><CRITERIANO>1</CRITERIANO></CRITERIA></INHERITS>");
                f.WorkflowPermissionHelper.CanEditProtected().Returns(true);

                var r = f.Subject.Search("1");

                Assert.Equal(1, r.TotalCount);
                Assert.True(r.CanEditProtected);
                Assert.True(r.HasOffices);
            }
        }

        public class ChangeParentInheritanceMethodFacts : FactBase
        {
            [Fact]
            public void BreaksInheritance()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);
                var newParentCriteria = new CriteriaBuilder().Build().In(Db);
                var putParams = new WorkflowInheritanceController.ChangeParentInheritanceParams {NewParent = newParentCriteria.Id, ReplaceCommonRules = true};
                var criteria = new CriteriaBuilder().Build().In(Db);
                f.Subject.ChangeParentInheritance(criteria.Id, putParams);
                f.WorkflowInheritanceService.Received(1).BreakInheritance(criteria.Id);
            }

            [Fact]
            public void ChecksEditPermission()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);
                var newParentCriteria = new CriteriaBuilder().Build().In(Db);
                var putParams = new WorkflowInheritanceController.ChangeParentInheritanceParams {NewParent = newParentCriteria.Id, ReplaceCommonRules = true};
                var criteria = new CriteriaBuilder().Build().In(Db);
                f.Subject.ChangeParentInheritance(criteria.Id, putParams);
                f.WorkflowPermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
            }

            [Fact]
            public void CreatesNewInheritanceLink()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);
                var parent = new CriteriaBuilder().Build().In(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);
                var putParams = new WorkflowInheritanceController.ChangeParentInheritanceParams {NewParent = parent.Id, ReplaceCommonRules = true};
                f.Subject.ChangeParentInheritance(criteria.Id, putParams);

                Assert.Equal(parent.Id, criteria.ParentCriteriaId);
                Assert.NotNull(Db.Set<Inherits>().SingleOrDefault(_ => _.CriteriaNo == criteria.Id && _.FromCriteriaNo == parent.Id));
            }

            [Fact]
            public void InheritsNewEventRules()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);
                var parent = new CriteriaBuilder().Build().In(Db);
                var @event = new ValidEventBuilder().For(parent, null).Build().In(Db);
                var event1 = new ValidEventBuilder().For(parent, null).Build().In(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);
                var putParams = new WorkflowInheritanceController.ChangeParentInheritanceParams {NewParent = parent.Id, ReplaceCommonRules = Fixture.Boolean()};
                f.Subject.ChangeParentInheritance(criteria.Id, putParams);
                f.WorkflowEventInheritanceService.Received(1).InheritNewEventRules(criteria, Arg.Is<IEnumerable<ValidEvent>>(_ => _.First().EventId == @event.EventId && _.Last().EventId == event1.EventId), putParams.ReplaceCommonRules);
            }

            [Fact]
            public void PassesEventsAndEntriesToDescendants()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);

                var newParentCriteria = new CriteriaBuilder().Build().In(Db);
                var parentEvent = new ValidEventBuilder().For(newParentCriteria, null).Build().In(Db);
                var parentEntry = DataEntryTaskBuilder.ForCriteria(newParentCriteria).Build().In(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var childCriteria1 = new CriteriaBuilder().Build().In(Db);
                var childCriteria2 = new CriteriaBuilder().Build().In(Db);

                new InheritsBuilder(criteria, childCriteria1).Build().In(Db);
                new InheritsBuilder(criteria, childCriteria2).Build().In(Db);

                var inheritedEventsResult = new ValidEventBuilder().Build().In(Db);
                f.WorkflowEventInheritanceService.InheritNewEventRules(criteria, Arg.Any<IEnumerable<ValidEvent>>(), Arg.Any<bool>()).Returns(new[] {inheritedEventsResult});
                var inheritedEntriesResult = new DataEntryTaskBuilder().Build().In(Db);
                f.WorkflowEntryInheritanceService.InheritNewEntries(criteria, Arg.Any<IEnumerable<DataEntryTask>>(), Arg.Any<bool>()).Returns(new[] {inheritedEntriesResult});

                var putParams = new WorkflowInheritanceController.ChangeParentInheritanceParams {NewParent = newParentCriteria.Id, ReplaceCommonRules = Fixture.Boolean()};

                f.Subject.ChangeParentInheritance(criteria.Id, putParams);

                // main criteria gets parent valid events and entries
                f.WorkflowEventInheritanceService.Received(1).InheritNewEventRules(criteria, Arg.Is<IEnumerable<ValidEvent>>(_ => _.First().EventId == parentEvent.EventId), putParams.ReplaceCommonRules);
                f.WorkflowEntryInheritanceService.Received(1).InheritNewEntries(criteria, Arg.Is<IEnumerable<DataEntryTask>>(_ => _.First().Description == parentEntry.Description), putParams.ReplaceCommonRules);

                // push inherited rules down the tree
                f.WorkflowInheritanceService.Received(1).PushDownInheritanceTree(criteria.Id, Arg.Is<IEnumerable<ValidEvent>>(_ => _.First().EventId == inheritedEventsResult.EventId), Arg.Is<IEnumerable<DataEntryTask>>(_ => _.First().Description == inheritedEntriesResult.Description), putParams.ReplaceCommonRules);
            }

            [Fact]
            public void RequiresNewParentId()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);
                var putParams = new WorkflowInheritanceController.ChangeParentInheritanceParams {NewParent = null, ReplaceCommonRules = true};
                Assert.Throws<ArgumentNullException>(() => f.Subject.ChangeParentInheritance(1, putParams));
            }

            [Fact]
            public void ThrowsExceptionWhenMovingProtectedToUnprotectedParent()
            {
                var f = new WorkflowInheritanceControllerFixture(Db);

                var newParentCriteria = new CriteriaBuilder().Build().In(Db);
                newParentCriteria.IsProtected = false;

                var criteria = new CriteriaBuilder().Build().In(Db);
                criteria.IsProtected = true;

                var putParams = new WorkflowInheritanceController.ChangeParentInheritanceParams {NewParent = newParentCriteria.Id, ReplaceCommonRules = Fixture.Boolean()};
                Assert.Throws<HttpResponseException>(() => f.Subject.ChangeParentInheritance(criteria.Id, putParams));
            }
        }

        [Fact]
        public void BreakInheritanceCallsServiceWithCriteriaId()
        {
            var f = new WorkflowInheritanceControllerFixture(Db);

            f.Subject.BreakInheritance(123);

            f.WorkflowPermissionHelper.Received(1).EnsureEditPermission(123);
            f.WorkflowInheritanceService.Received(1).BreakInheritance(123);
        }
    }

    public class WorkflowInheritanceControllerFixture : IFixture<WorkflowInheritanceController>
    {
        public WorkflowInheritanceControllerFixture(InMemoryDbContext db)
        {
            WorkflowInheritanceService = Substitute.For<IWorkflowInheritanceService>();
            WorkflowPermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
            WorkflowEntryInheritanceService = Substitute.For<IWorkflowEntryInheritanceService>();
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            WorkflowMaintenanceService = Substitute.For<IWorkflowMaintenanceService>();

            Subject = new WorkflowInheritanceController(WorkflowInheritanceService, WorkflowPermissionHelper, db,
                                                        WorkflowEventInheritanceService, WorkflowEntryInheritanceService, WorkflowMaintenanceService);
        }

        public IWorkflowInheritanceService WorkflowInheritanceService { get; set; }

        public IWorkflowPermissionHelper WorkflowPermissionHelper { get; set; }
        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; set; }
        public IWorkflowEntryInheritanceService WorkflowEntryInheritanceService { get; set; }
        public IWorkflowMaintenanceService WorkflowMaintenanceService { get; set; }
        public WorkflowInheritanceController Subject { get; }
    }
}