using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ScreenDesigner.Cases
{
    public class CaseScreenDesignerInheritanceServiceFacts : FactBase
    {
        public class GetInheritanceTreeXml : FactBase
        {
            [Fact]
            public void CallsTheCorrectMethodOnDbContext()
            {
                var db = Substitute.For<IDbContext>();
                var f = new CaseScreenDesignerInheritanceServiceFixture(db);
                f.PreferredCultureResolver.Resolve().Returns("test Culture");
                f.Subject.GetInheritanceTreeXml(new[] { 1, 2, 3 });

                db.Received(1).GetCaseScreenDesignerInheritanceTree("test Culture", new[] { 1, 2, 3 });
            }

        }

        public class CaseScreenDesignerInheritanceServiceFixture : IFixture<CaseScreenDesignerInheritanceService>
        {
            public CaseScreenDesignerInheritanceServiceFixture(IDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                DbContext = db;
                WorkflowPermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
                WorkflowEntryInheritanceService = Substitute.For<IWorkflowEntryInheritanceService>();

                WorkflowEventControlService = Substitute.For<IWorkflowEventControlService>();
                ValidEventService = Substitute.For<IValidEventService>();
                WorkflowEntryControlService = Substitute.For<IWorkflowEntryControlService>();
                EntryService = Substitute.For<IEntryService>();
                Inheritance = Substitute.For<IInheritance>();

                Subject = new CaseScreenDesignerInheritanceService(DbContext, PreferredCultureResolver);
            }

            public IDbContext DbContext { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public IWorkflowPermissionHelper WorkflowPermissionHelper { get; set; }
            public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; set; }
            public IWorkflowEntryInheritanceService WorkflowEntryInheritanceService { get; set; }

            public IWorkflowEventControlService WorkflowEventControlService { get; set; }
            public IValidEventService ValidEventService { get; set; }
            public IWorkflowEntryControlService WorkflowEntryControlService { get; set; }
            public IEntryService EntryService { get; set; }
            public IInheritance Inheritance { get; set; }
            public CaseScreenDesignerInheritanceService Subject { get; set; }
        }
    }
}