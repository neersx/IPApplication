using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class CaseScreenDesignerInheritanceControllerFacts : FactBase
    {
        public class ParseTreeMethod : FactBase
        {
            [Fact]
            public void ParsesMultipleTrees()
            {
                var f = new CaseScreenDesignerInheritanceControllerFixture(Db);
                var id1 = 1;
                var name1 = "a";
                var id2 = 2;
                var name2 = "b";
                var xml = $"<INHERITS><CRITERIA><CRITERIANO>{id1}</CRITERIANO><DESCRIPTION>{name1}</DESCRIPTION></CRITERIA><CRITERIA><CRITERIANO>{id2}</CRITERIANO><DESCRIPTION>{name2}</DESCRIPTION></CRITERIA></INHERITS>";
                var totalCount = 0;

                var trees = f.Subject.ParseTrees(XElement.Parse(xml), new[] { 1 }, out totalCount);

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

                var f = new CaseScreenDesignerInheritanceControllerFixture(Db);
                var tree = f.Subject.ParseTree(XElement.Parse(parentXml), new[] { 22, 2, 1 });

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
                var f = new CaseScreenDesignerInheritanceControllerFixture(Db);

                new Office().In(Db);
                f.CaseScreenDesignerInheritanceService.GetInheritanceTreeXml(Arg.Is<IEnumerable<int>>(_ => _.First() == 1)).Returns("<INHERITS><CRITERIA><CRITERIANO>1</CRITERIANO></CRITERIA></INHERITS>");
                f.CaseScreenDesignerInheritanceService.GetInheritanceTreeXml(Arg.Is<IEnumerable<int>>(_ => _.First() == 2)).Returns("<INHERITS><CRITERIA><CRITERIANO>2</CRITERIANO></CRITERIA></INHERITS>");
                f.PermissionHelper.CanEditProtected().Returns(true);

                var r = f.Subject.Search("1", 2);

                Assert.Equal(2, r.TotalCount);
                Assert.Equal(2, r.Trees.First().Id);
                Assert.Equal(1, r.Trees.Last().Id);
            }

            [Fact]
            public void ReturnsTreeData()
            {
                var f = new CaseScreenDesignerInheritanceControllerFixture(Db);

                new Office().In(Db);
                f.CaseScreenDesignerInheritanceService.GetInheritanceTreeXml(null).ReturnsForAnyArgs("<INHERITS><CRITERIA><CRITERIANO>1</CRITERIANO></CRITERIA></INHERITS>");
                f.PermissionHelper.CanEditProtected().Returns(true);

                var r = f.Subject.Search("1");

                Assert.Equal(1, r.TotalCount);
                Assert.True(r.CanEditProtected);
                Assert.True(r.HasOffices);
            }
        }
    }

    public class CaseScreenDesignerInheritanceControllerFixture : IFixture<CaseScreenDesignerInheritanceController>
    {
        public CaseScreenDesignerInheritanceControllerFixture(InMemoryDbContext db)
        {
            CaseScreenDesignerInheritanceService = Substitute.For<ICaseScreenDesignerInheritanceService>();
            PermissionHelper = Substitute.For<ICaseScreenDesignerPermissionHelper>();

            Subject = new CaseScreenDesignerInheritanceController(PermissionHelper, db, CaseScreenDesignerInheritanceService);
        }

        public ICaseScreenDesignerInheritanceService CaseScreenDesignerInheritanceService { get; set; }

        public ICaseScreenDesignerPermissionHelper PermissionHelper { get; set; }
        public CaseScreenDesignerInheritanceController Subject { get; }
    }
}