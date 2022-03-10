using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Checklists;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.Checklists
{
    public class ChecklistMaintenanceServiceFacts
    {
        public class CreateCriteria : FactBase
        {
            [Fact]
            public void ThrowsErrorIfCannotCreateProtectedRules()
            {
                var formData = new ChecklistSaveModel
                {
                    CriteriaName = Fixture.UniqueName(),
                    IsProtected = true
                };
                var f = new ChecklistMaintenanceServiceFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create).Returns(false);
                Assert.Throws<Exception>(() => f.Subject.CreateChecklistCriteria(formData));
                Assert.False(Db.Set<Criteria>().Any());
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void CreatesCriteria(bool isProtected)
            {
                var f = new ChecklistMaintenanceServiceFixture(Db);

                var office = new OfficeBuilder().Build().In(Db).Id;
                var caseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db).Code;
                var jurisdiction = new CountryBuilder { Id = "AU" }.Build().In(Db).Id;
                var propertyType = new PropertyTypeBuilder { Id = "T" }.Build().In(Db).Code;
                var caseCategory = new CaseCategoryBuilder { CaseCategoryId = "CC" }.Build().In(Db).CaseCategoryId;
                var subType = new SubTypeBuilder { Id = "ST" }.Build().In(Db).Code;
                var basis = new ApplicationBasisBuilder { Id = "AB" }.Build().In(Db).Code;
                var checklist = new ChecklistBuilder().Build().In(Db).Id;
                var formData = new ChecklistSaveModel
                {
                    CriteriaName = Fixture.UniqueName(),
                    IsProtected = isProtected,
                    IsLocalClient = true,
                    Office = office,
                    CaseType = caseType,
                    Jurisdiction = jurisdiction,
                    PropertyType = propertyType,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Basis = basis,
                    Checklist = checklist
                };

                var result = f.Subject.CreateChecklistCriteria(formData);
                f.LastInternalCodeGenerator.Received(1).GenerateLastInternalCode(KnownInternalCodeTable.Criteria);
                f.CriteriaMaintenanceValidator.Received(1).ValidateCriteriaName(formData.CriteriaName);
                f.CriteriaMaintenanceValidator.Received(1).ValidateDuplicateCriteria(Arg.Is<Criteria>(_ => _.IsProtected == isProtected && _.Description == formData.CriteriaName), true);

                var c = f.DbContext.Set<Criteria>().First(_ => _.Description == formData.CriteriaName);
                Assert.Equal(office, c.OfficeId);
                Assert.Equal(caseType, c.CaseTypeId);
                Assert.Equal(jurisdiction, c.CountryId);
                Assert.Equal(propertyType, c.PropertyTypeId);
                Assert.Equal(caseCategory, c.CaseCategoryId);
                Assert.Equal(subType, c.SubTypeId);
                Assert.Equal(basis, c.BasisId);
                Assert.Equal(checklist, c.ChecklistType);
                Assert.Equal(10, c.Id);

                Assert.Equal(10, result.CriteriaId);
                Assert.True(result.Status);
            }
        }
    }

    public class ChecklistMaintenanceServiceFixture : IFixture<ChecklistMaintenanceService>
    {
        public ChecklistMaintenanceServiceFixture(InMemoryDbContext db)
        {
            DbContext = db;
            LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
            LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Criteria).Returns(10);
            CriteriaMaintenanceValidator = Substitute.For<ICriteriaMaintenanceValidator>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(true);
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create).Returns(true);
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules).Returns(true);
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create).Returns(true);

            Subject = new ChecklistMaintenanceService(DbContext, LastInternalCodeGenerator, CriteriaMaintenanceValidator, TaskSecurityProvider);
        }

        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public ICriteriaMaintenanceValidator CriteriaMaintenanceValidator { get; set; }
        public InMemoryDbContext DbContext { get; set; }
        public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
        public IInheritance Inheritance { get; set; }
        public ChecklistMaintenanceService Subject { get; set; }
    }
}