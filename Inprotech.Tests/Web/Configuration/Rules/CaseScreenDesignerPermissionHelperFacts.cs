using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class CaseScreenDesignerPermissionHelperFacts : FactBase
    {
        [Theory]
        [InlineData(false, false, false, false)]
        [InlineData(false, false, true, false)]
        [InlineData(false, true, true, true)]
        [InlineData(false, true, false, true)]
        [InlineData(true, false, true, false)]
        [InlineData(true, false, false, true)]
        public void TestCanEditMethod(bool canEdit, bool canEditProtected, bool isProtected, bool result)
        {
            var c = new CriteriaBuilder {UserDefinedRule = isProtected ? 0 : 1}.ForEventsEntriesRule().Build().In(Db);
            var f = new Fixture(Db);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules).Returns(canEdit);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(canEditProtected);
            f.Inheritance.CheckAnyProtectedDescendantsInTree(Arg.Any<int>()).ReturnsForAnyArgs(false);

            bool isEditBlockedByDescendants;
            var r = f.Subject.CanEdit(c, out isEditBlockedByDescendants);

            Assert.Equal(result, r);
            Assert.False(isEditBlockedByDescendants);
        }

        public class CanEditProtectionLevelFlagsMethod : FactBase
        {
            [Theory]
            [InlineData(1, 1, true)]
            [InlineData(0, 0, false)]
            [InlineData(0, 1, false)]
            [InlineData(1, 0, false)]
            public void CantMakeCriteriaProtectedIfParentUnprotected(int isUnprotected, int parentUnprotected, bool expectedResult)
            {
                var f = new Fixture(Db);
                var inherits = new InheritsBuilder(new CriteriaBuilder {UserDefinedRule = parentUnprotected}.Build(),
                                                   new CriteriaBuilder {UserDefinedRule = isUnprotected}.Build()).Build().In(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(true);

                bool blockedByParent;
                bool blockedByDescendants;
                f.Subject.GetEditProtectionLevelFlags(inherits.Criteria, out blockedByParent, out blockedByDescendants);

                Assert.Equal(expectedResult, blockedByParent);
                Assert.False(blockedByDescendants);
            }

            [Theory]
            [InlineData(1, 1, true)]
            [InlineData(0, 0, false)]
            [InlineData(0, 1, false)]
            [InlineData(1, 0, false)]
            public void CantMakeCriteraUnprotectedIfProtectedChild(int isProtected, int hasProtectedChild, bool expectedResult)
            {
                var f = new Fixture(Db);
                var criteria = new CriteriaBuilder {UserDefinedRule = isProtected == 1 ? 0 : 1}.Build().In(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(true);
                f.Inheritance.CheckAnyProtectedDescendantsInTree(criteria.Id).Returns(hasProtectedChild == 1);

                bool blockedByParent;
                bool blockedByDescendants;
                f.Subject.GetEditProtectionLevelFlags(criteria, out blockedByParent, out blockedByDescendants);

                Assert.False(blockedByParent);
                Assert.Equal(expectedResult, blockedByDescendants);
            }

            [Fact]
            public void BlockedByCanEdit()
            {
                var f = new Fixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(false);

                bool blockedByParent;
                bool blockedByDescendants;
                f.Subject.GetEditProtectionLevelFlags(criteria, out blockedByParent, out blockedByDescendants);

                Assert.False(blockedByParent);
                Assert.False(blockedByDescendants);
            }
        }

        public class EnsureEditProtectionLevelAllowedFacts : FactBase
        {
            [Theory]
            [InlineData(0, false)]
            [InlineData(1, true)]
            public void ThrowsExceptionWhenTryingToMakeCriteriaProtectedWithUnprotectedParent(int newIsProtected, bool expectException)
            {
                var f = new Fixture(Db);
                var inherits = new InheritsBuilder(new CriteriaBuilder {UserDefinedRule = 1}.Build(),
                                                   new CriteriaBuilder {UserDefinedRule = 1}.Build()).Build().In(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(true);

                var e = Record.Exception(() => { f.Subject.EnsureEditProtectionLevelAllowed(inherits.Criteria, newIsProtected == 1); });

                if (expectException)
                {
                    Assert.NotNull(e);
                }
                else
                {
                    Assert.Null(e);
                }
            }

            [Theory]
            [InlineData(0, true)]
            [InlineData(1, false)]
            public void ThrowsExceptionWhenTryingToMakeCriteriaUnprotectedWithProtectedChildren(int newIsProtected, bool expectException)
            {
                var f = new Fixture(Db);
                var criteria = new CriteriaBuilder {UserDefinedRule = 0}.Build().In(Db);
                f.Inheritance.CheckAnyProtectedDescendantsInTree(criteria.Id).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(true);

                var e = Record.Exception(() => { f.Subject.EnsureEditProtectionLevelAllowed(criteria, newIsProtected == 1); });

                if (expectException)
                {
                    Assert.NotNull(e);
                }
                else
                {
                    Assert.Null(e);
                }
            }
        }
        public class EnsureDeletePermission : FactBase
        {
            [Theory]
            [InlineData(null, false)]
            [InlineData(null, true)]
            [InlineData(ApplicationTask.MaintainRules, true)]
            public void ThrowsExceptionIfUserDoesNotHaveTaskSecurity(ApplicationTask? taskUserHas, bool isProtected)
            {
                var f = new Fixture(Db);

                if (taskUserHas.HasValue)
                {
                    f.TaskSecurityProvider.HasAccessTo(taskUserHas.Value).Returns(true);
                }

                Assert.Throws<HttpResponseException>(() => f.Subject.EnsureDeletePermission(new Criteria {UserDefinedRule = isProtected ? 0 : 1}));
            }

            [Theory]
            [InlineData(ApplicationTask.MaintainRules, false)]
            [InlineData(ApplicationTask.MaintainCpassRules, false)]
            [InlineData(ApplicationTask.MaintainCpassRules, true)]
            public void DoesNotThrowExceptionIfUserHasTaskSecurity(ApplicationTask taskUserHas, bool isProtected)
            {
                var f = new Fixture(Db);
                f.TaskSecurityProvider.HasAccessTo(taskUserHas).Returns(true);

                Assert.Null(Record.Exception(() => f.Subject.EnsureDeletePermission(new Criteria {UserDefinedRule = isProtected ? 0 : 1})));
            }
        }

        class Fixture : IFixture<ICaseScreenDesignerPermissionHelper>
        {
            readonly InMemoryDbContext _db;

            public Fixture(InMemoryDbContext db)
            {
                _db = db;
                WorkflowInheritanceService = Substitute.For<IWorkflowInheritanceService>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Inheritance = Substitute.For<IInheritance>();
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; }

            public IWorkflowInheritanceService WorkflowInheritanceService { get; }

            public IInheritance Inheritance { get; }

            public ICaseScreenDesignerPermissionHelper Subject => new CaseScreenDesignerPermissionHelper(_db, TaskSecurityProvider, Inheritance);
        }

        [Fact]
        public void CanEditProtected()
        {
            var f = new Fixture(Db);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(true);
            var r = f.Subject.CanEditProtected();
            Assert.True(r);
        }

        [Fact]
        public void TreatsCriteriaAsProtectedIfProtectedDescendants()
        {
            var f = new Fixture(Db);
            // unprotected criteria and can edit unprotected permission
            var c = new CriteriaBuilder {UserDefinedRule = 1}.ForEventsEntriesRule().Build().In(Db);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules).Returns(true);

            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(false);
            f.Inheritance.CheckAnyProtectedDescendantsInTree(Arg.Any<int>()).ReturnsForAnyArgs(true);

            bool isEditBlockedByDescendants;
            var canEditResult = f.Subject.CanEdit(c, out isEditBlockedByDescendants);

            Assert.False(canEditResult);
            Assert.True(isEditBlockedByDescendants);
        }
    }
}