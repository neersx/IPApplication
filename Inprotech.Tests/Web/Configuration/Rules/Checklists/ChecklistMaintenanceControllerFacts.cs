using System;
using Autofac.Features.Indexed;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Checklists;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.Checklists
{
    public class ChecklistMaintenanceControllerFacts
    {
        public class CreateChecklistCriteria : FactBase
        {
            [Fact]
            public void ThrowsExceptionForInvalidCombination()
            {
                var model = new ChecklistSaveModel
                {
                    CriteriaName = Fixture.String()
                };
                var f = new ChecklistMaintenanceControllerFixture();
                var output = new ValidatedCharacteristics
                {
                    Checklist = new ValidatedCharacteristic(isValid: false)
                };
                f.CharacteristicsValidator.Validate(Arg.Any<ChecklistSaveModel>()).Returns(output);
                Assert.Throws<Exception>(() => f.Subject.CreateWorkflow(model));
                f.CharacteristicsValidator.Received(1).Validate(model);
                f.ChecklistMaintenanceService.DidNotReceive().CreateChecklistCriteria(Arg.Any<ChecklistSaveModel>());
            }

            [Fact]
            public void ThrowsExceptionForBlankCriteriaName()
            {
                var model = new ChecklistSaveModel
                {
                    CriteriaName = string.Empty
                };
                var f = new ChecklistMaintenanceControllerFixture();
                f.CharacteristicsValidator.Validate(Arg.Any<ChecklistSaveModel>()).Returns(new ValidatedCharacteristics { Checklist = new ValidatedCharacteristic(isValid: true) });
                Assert.Throws<Exception>(() => f.Subject.CreateWorkflow(model));
                f.CharacteristicsValidator.Received(1).Validate(model);
                f.ChecklistMaintenanceService.DidNotReceive().CreateChecklistCriteria(Arg.Any<ChecklistSaveModel>());
            }

            [Fact]
            public void CallsChecklistMaintenanceService()
            {
                var model = new ChecklistSaveModel
                {
                    CriteriaName = Fixture.UniqueName()
                };
                var f = new ChecklistMaintenanceControllerFixture();
                f.CharacteristicsValidator.Validate(Arg.Any<ChecklistSaveModel>()).Returns(new ValidatedCharacteristics { Checklist = new ValidatedCharacteristic(isValid: true) });
                f.Subject.CreateWorkflow(model);
                f.CharacteristicsValidator.Received(1).Validate(model);
                f.ChecklistMaintenanceService.Received(1).CreateChecklistCriteria(model);
            }
        }
    }

    public class ChecklistMaintenanceControllerFixture : IFixture<ChecklistMaintenanceController>
    {
        public ChecklistMaintenanceControllerFixture()
        {
            CharacteristicsValidator = Substitute.For<ICharacteristicsValidator>();
            ChecklistMaintenanceService = Substitute.For<IChecklistMaintenanceService>();
            var characteristicsServiceIndex = Substitute.For<IIndex<string, ICharacteristicsValidator>>();
            characteristicsServiceIndex[CriteriaPurposeCodes.CheckList].Returns(CharacteristicsValidator);
            Subject = new ChecklistMaintenanceController(characteristicsServiceIndex, ChecklistMaintenanceService);
        }

        public IChecklistMaintenanceService ChecklistMaintenanceService { get; set; }
        public ICharacteristicsValidator CharacteristicsValidator { get; set; }
        public ChecklistMaintenanceController Subject { get; }
    }
}