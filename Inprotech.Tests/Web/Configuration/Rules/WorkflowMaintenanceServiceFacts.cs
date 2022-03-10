using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowMaintenanceServiceFacts
    {
        public class CreateCriteria : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void CreatesCriteria(bool useExamination)
            {
                var f = new WorkflowMaintenanceServiceFixture(Db).WithEditProtectedPermission();

                var office = new OfficeBuilder().Build().In(Db).Id;
                var caseType = new CaseTypeBuilder {Id = "A"}.Build().In(Db).Code;
                var jurisdiction = new CountryBuilder {Id = "AU"}.Build().In(Db).Id;
                var propertyType = new PropertyTypeBuilder {Id = "T"}.Build().In(Db).Code;
                var caseCategory = new CaseCategoryBuilder {CaseCategoryId = "CC"}.Build().In(Db).CaseCategoryId;
                var subType = new SubTypeBuilder {Id = "ST"}.Build().In(Db).Code;
                var basis = new ApplicationBasisBuilder {Id = "AB"}.Build().In(Db).Code;
                var action = new ActionBuilder {Id = "AN"}.Build().In(Db).Code;
                var dateOfLaw = new DateOfLawBuilder().Build().In(Db).Date;

                int? examinationTypeId = null;
                int? renewalTypeId = null;

                if (useExamination)
                {
                    examinationTypeId = new TableCodeBuilder().For(TableTypes.ExaminationType).Build().In(Db).Id;
                }
                else
                {
                    renewalTypeId = new TableCodeBuilder().For(TableTypes.RenewalType).Build().In(Db).Id;
                }

                var formData = new WorkflowSaveModel
                {
                    CriteriaName = "ABC",
                    IsProtected = true,
                    IsLocalClient = true,
                    Office = office,
                    CaseType = caseType,
                    Jurisdiction = jurisdiction,
                    PropertyType = propertyType,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Basis = basis,
                    Action = action,
                    DateOfLaw = dateOfLaw.ToString("yyyy-MM-dd"),
                    ExaminationType = examinationTypeId,
                    RenewalType = renewalTypeId
                };

                f.Subject.CreateWorkflow(formData);

                var c = f.DbContext.Set<Criteria>().First(_ => _.Description == formData.CriteriaName);
                Assert.Equal(office, c.OfficeId);
                Assert.Equal(caseType, c.CaseTypeId);
                Assert.Equal(jurisdiction, c.CountryId);
                Assert.Equal(propertyType, c.PropertyTypeId);
                Assert.Equal(caseCategory, c.CaseCategoryId);
                Assert.Equal(subType, c.SubTypeId);
                Assert.Equal(basis, c.BasisId);
                Assert.Equal(action, c.ActionId);
                Assert.Equal(dateOfLaw, c.DateOfLaw);
                Assert.Equal(examinationTypeId ?? renewalTypeId, c.TableCodeId);
            }

            [Fact]
            public void CreatesNegativeCriteria()
            {
                var f = new WorkflowMaintenanceServiceFixture(Db).WithEditProtectedPermission().WithCreateNegativeCriteriaPermission();

                var office = new OfficeBuilder().Build().In(Db).Id;
                var caseType = new CaseTypeBuilder {Id = "A"}.Build().In(Db).Code;
                var jurisdiction = new CountryBuilder {Id = "AU"}.Build().In(Db).Id;
                var propertyType = new PropertyTypeBuilder {Id = "T"}.Build().In(Db).Code;
                var caseCategory = new CaseCategoryBuilder {CaseCategoryId = "CC"}.Build().In(Db).CaseCategoryId;
                var subType = new SubTypeBuilder {Id = "ST"}.Build().In(Db).Code;
                var basis = new ApplicationBasisBuilder {Id = "AB"}.Build().In(Db).Code;
                var action = new ActionBuilder {Id = "AN"}.Build().In(Db).Code;
                var dateOfLaw = new DateOfLawBuilder().Build().In(Db).Date;

                int? examinationTypeId = null;
                int? renewalTypeId = null;
                renewalTypeId = new TableCodeBuilder().For(TableTypes.RenewalType).Build().In(Db).Id;

                var formData = new WorkflowSaveModel
                {
                    CriteriaName = "ABC",
                    IsProtected = true,
                    IsLocalClient = true,
                    Office = office,
                    CaseType = caseType,
                    Jurisdiction = jurisdiction,
                    PropertyType = propertyType,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Basis = basis,
                    Action = action,
                    DateOfLaw = dateOfLaw.ToString("yyyy-MM-dd"),
                    ExaminationType = examinationTypeId,
                    RenewalType = renewalTypeId
                };

                f.Subject.CreateWorkflow(formData);

                var c = f.DbContext.Set<Criteria>().First(_ => _.Description == formData.CriteriaName);
                Assert.Equal(office, c.OfficeId);
                Assert.Equal(caseType, c.CaseTypeId);
                Assert.Equal(jurisdiction, c.CountryId);
                Assert.Equal(propertyType, c.PropertyTypeId);
                Assert.Equal(caseCategory, c.CaseCategoryId);
                Assert.Equal(subType, c.SubTypeId);
                Assert.Equal(basis, c.BasisId);
                Assert.Equal(action, c.ActionId);
                Assert.Equal(dateOfLaw, c.DateOfLaw);
                Assert.Equal(examinationTypeId ?? renewalTypeId, c.TableCodeId);
                Assert.True(c.Id < 0);
            }
        }

        public class UpdateWorkflow : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void UpdatesCriteria(bool useExamination)
            {
                var f = new WorkflowMaintenanceServiceFixture(Db);

                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var office = new OfficeBuilder().Build().In(Db).Id;
                var caseType = new CaseTypeBuilder {Id = "A"}.Build().In(Db).Code;
                var jurisdiction = new CountryBuilder {Id = "AU"}.Build().In(Db).Id;
                var propertyType = new PropertyTypeBuilder {Id = "T"}.Build().In(Db).Code;
                var caseCategory = new CaseCategoryBuilder {CaseCategoryId = "CC"}.Build().In(Db).CaseCategoryId;
                var subType = new SubTypeBuilder {Id = "ST"}.Build().In(Db).Code;
                var basis = new ApplicationBasisBuilder {Id = "AB"}.Build().In(Db).Code;
                var action = new ActionBuilder {Id = "AN"}.Build().In(Db).Code;
                var dateOfLaw = new DateOfLawBuilder().Build().In(Db).Date;

                int? examinationTypeId = null;
                int? renewalTypeId = null;

                if (useExamination)
                {
                    examinationTypeId = new TableCodeBuilder().For(TableTypes.ExaminationType).Build().In(Db).Id;
                }
                else
                {
                    renewalTypeId = new TableCodeBuilder().For(TableTypes.RenewalType).Build().In(Db).Id;
                }

                var formData = new WorkflowSaveModel
                {
                    Id = c.Id,
                    CriteriaName = "ABC",
                    IsProtected = true,
                    IsLocalClient = true,
                    Office = office,
                    CaseType = caseType,
                    Jurisdiction = jurisdiction,
                    PropertyType = propertyType,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Basis = basis,
                    Action = action,
                    DateOfLaw = dateOfLaw.ToString("yyyy-MM-dd"),
                    ExaminationType = examinationTypeId,
                    RenewalType = renewalTypeId
                };

                f.Subject.UpdateWorkflow(c.Id, formData);

                Assert.Equal(office, c.OfficeId);
                Assert.Equal(caseType, c.CaseTypeId);
                Assert.Equal(jurisdiction, c.CountryId);
                Assert.Equal(propertyType, c.PropertyTypeId);
                Assert.Equal(caseCategory, c.CaseCategoryId);
                Assert.Equal(subType, c.SubTypeId);
                Assert.Equal(basis, c.BasisId);
                Assert.Equal(action, c.ActionId);
                Assert.Equal(dateOfLaw, c.DateOfLaw);
                Assert.Equal(examinationTypeId ?? renewalTypeId, c.TableCodeId);
            }

            [Theory]
            [InlineData(0, 0, false)]
            [InlineData(0, 1, true)]
            [InlineData(1, 0, true)]
            [InlineData(1, 1, false)]
            public void ChecksCanEditProtectionLevelIfFlagEdited(int originalIsProtected, int newIsProtected, bool expectedCallReceived)
            {
                var f = new WorkflowMaintenanceServiceFixture(Db);

                var c = new CriteriaBuilder { UserDefinedRule = originalIsProtected }.ForEventsEntriesRule().Build().In(Db);

                var formData = new WorkflowSaveModel
                {
                    CriteriaName = Fixture.String(),
                    IsProtected = newIsProtected == 0
                };
                f.Subject.UpdateWorkflow(c.Id, formData);
                f.PermissionHelper.Received(expectedCallReceived ? 1 : 0).EnsureEditProtectionLevelAllowed(c, newIsProtected == 0);
            }
        }

        public class ResetWorkflow : FactBase
        {
            [Fact]
            public void ResetsEventsAndEntries()
            {
                var f = new WorkflowMaintenanceServiceFixture(Db);

                var parent = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(parent, criteria).Build().In(Db);

                var applyToDescendants = Fixture.Boolean();
                var updateRespNameOnCases = Fixture.Boolean();
                var result = f.Subject.ResetWorkflow(criteria, applyToDescendants, updateRespNameOnCases);

                f.WorkflowInheritanceService.Received(1).ResetEventControl(criteria, applyToDescendants, updateRespNameOnCases, parent);
                f.WorkflowInheritanceService.Received(1).ResetEntries(criteria, applyToDescendants, parent);
                Assert.Equal("Success", result);
            }

            [Fact]
            public void ReturnsIfNameRespChanges()
            {
                var f = new WorkflowMaintenanceServiceFixture(Db);

                var parent = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(parent, criteria).Build().In(Db);

                var @event = new EventBuilder().Build();
                var parentEvent = new ValidEventBuilder().For(parent, @event).Build().In(Db);
                var childEvent = new ValidEventBuilder().For(parent, @event).Build().In(Db);
                parent.ValidEvents.Add(parentEvent);
                criteria.ValidEvents.Add(childEvent);

                f.WorkflowEventControlService.CheckDueDateRespNameChange(null, null).ReturnsForAnyArgs(true);

                var result = f.Subject.ResetWorkflow(criteria, true, null);

                Assert.Equal("updateNameRespOnCases", result);
            }
        }

        public class CheckCriteriaUsedByLiveCasesMethod : FactBase
        {
            readonly Case _case;
            readonly Criteria _criteria;
            readonly WorkflowMaintenanceServiceFixture _fixture;

            public CheckCriteriaUsedByLiveCasesMethod()
            {
                _fixture = new WorkflowMaintenanceServiceFixture(Db);
                _criteria = new CriteriaBuilder().Build().In(Db);
                _case = new CaseBuilder { HasNoDefaultStatus = true }.Build().In(Db);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            [InlineData(true, false)]
            [InlineData(false, true)]
            public void ReturnsTrueWhenUsedByLiveCase(bool isLiveStatus, bool isLiveRenewalStatus)
            {
                var liveStatus = new StatusBuilder { IsLive = true }.Build().In(Db);

                if (isLiveStatus)
                {
                    _case.CaseStatus = liveStatus;
                }

                if (isLiveRenewalStatus)
                {
                    _case.Property = new CasePropertyBuilder { Case = _case, Status = liveStatus }.Build().In(Db);
                }

                OpenActionBuilder.ForCaseAsValid(Db, _case, null, _criteria).Build().In(Db);

                var result = _fixture.Subject.CheckCriteriaUsedByLiveCases(_criteria.Id);
                Assert.True(result);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(true, false)]
            [InlineData(false, true)]
            public void ReturnsFalseWhenNotUsedByLiveCase(bool isDeadStatus, bool isDeadRenewalStatus)
            {
                var deadStatus = new StatusBuilder { IsLive = false }.Build().In(Db);

                if (isDeadStatus)
                {
                    _case.CaseStatus = deadStatus;
                }

                if (isDeadRenewalStatus)
                {
                    _case.Property = new CasePropertyBuilder { Case = _case, Status = deadStatus }.Build().In(Db);
                }

                OpenActionBuilder.ForCaseAsValid(Db, _case, null, _criteria).Build().In(Db);

                var result = _fixture.Subject.CheckCriteriaUsedByLiveCases(_criteria.Id);
                Assert.False(result);
            }
        }

        public class WorkflowMaintenanceServiceFixture : IFixture<IWorkflowMaintenanceService>
        {
            public WorkflowMaintenanceServiceFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                WorkflowEventControlService = Substitute.For<IWorkflowEventControlService>();
                WorkflowInheritanceService = Substitute.For<IWorkflowInheritanceService>();

                LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Criteria).Returns(10);
                LastInternalCodeGenerator.GenerateNegativeLastInternalCode(KnownInternalCodeTable.CriteriaMaxim).Returns(-10);
                CriteriaMaintenanceValidator = Substitute.For<ICriteriaMaintenanceValidator>();

                Subject = new WorkflowMaintenanceService(DbContext, PermissionHelper, LastInternalCodeGenerator, WorkflowEventControlService, WorkflowInheritanceService, CriteriaMaintenanceValidator);
            }

            public ICriteriaMaintenanceValidator CriteriaMaintenanceValidator { get; set; }
            public InMemoryDbContext DbContext { get; set; }

            public IWorkflowPermissionHelper PermissionHelper { get; set; }
            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
            public IInheritance Inheritance { get; set; }
            public IWorkflowEventControlService WorkflowEventControlService { get; set; }
            public IWorkflowInheritanceService WorkflowInheritanceService { get; set; }
            public IWorkflowMaintenanceService Subject { get; set; }

            public WorkflowMaintenanceServiceFixture WithEditProtectedPermission()
            {
                PermissionHelper.CanEditProtected().Returns(true);
                return this;
            }

            public WorkflowMaintenanceServiceFixture WithCreateNegativeCriteriaPermission()
            {
                PermissionHelper.CanCreateNegativeWorkflow().Returns(true);
                return this;
            }
        }
    }
}