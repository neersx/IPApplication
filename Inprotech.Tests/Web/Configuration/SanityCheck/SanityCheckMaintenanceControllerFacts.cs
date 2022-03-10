using System;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.SanityCheck;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.DataValidation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.SanityCheck
{
    public class SanityCheckMaintenanceControllerFacts : FactBase
    {
        public class TaskSecurity : FactBase
        {
            [Theory]
            [InlineData(nameof(SanityCheckMaintenanceController.SaveCaseRule), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
            [InlineData(nameof(SanityCheckMaintenanceController.GetViewDataCase), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
            [InlineData(nameof(SanityCheckMaintenanceController.UpdateCaseRule), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify)]
            [InlineData(nameof(SanityCheckMaintenanceController.DeleteCaseSanityCheckForCase), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Delete)]
            [InlineData(nameof(SanityCheckMaintenanceController.DeleteCaseSanityCheckForNames), ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Delete)]
            public void ShouldHaveCorrectRequireAccessAttribute(string method, ApplicationTask task, ApplicationTaskAccessLevel applicationTaskAccessLevel)
            {
                var methodInfo = typeof(SanityCheckMaintenanceController).GetMethod(method);
                Assert.NotNull(methodInfo);
                var attributes = methodInfo.GetCustomAttributes<RequiresAccessToAttribute>().ToArray();
                Assert.NotEmpty(attributes);
                Assert.Single(attributes.Where(a => a.Task == task && a.Level == applicationTaskAccessLevel));
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowExceptionIfIdsNotProvided()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.DeleteCaseSanityCheckForCase(Enumerable.Empty<int>().ToArray())).IgnoreAwaitForNSubstituteAssertion();

                Enumerable.Range(1, 3).ToList().ForEach(_ => { new DataValidation().In(Db); });

                var r = await f.Subject.DeleteCaseSanityCheckForCase(new[] { 1, 2 });
                Assert.Equal(1, Db.Set<DataValidation>().Count());

                var rn = await f.Subject.DeleteCaseSanityCheckForNames(new[] { 3 });
                Assert.Equal(0, Db.Set<DataValidation>().Count());
            }
        }

        public class SaveCaseMethod : FactBase
        {
            [Fact]
            public async Task PerformsMandatoryChecks()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.SaveCaseRule(new SanityCheckCaseViewModel()));

                var model = new SanityCheckCaseViewModel { RuleOverview = { DisplayMessage = "Arthur" } };
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.SaveCaseRule(model));
            }

            [Fact]
            public async Task VerifiesValidCombination()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                f.CharacteristicsValidator.Validate(Arg.Any<WorkflowCharacteristics>()).Returns(new ValidatedCharacteristics { PropertyType = new ValidatedCharacteristic(null, null, false) });
                var model = new SanityCheckCaseViewModel { RuleOverview = { DisplayMessage = "Arthur", RuleDescription = "A" } };

                await Assert.ThrowsAsync<Exception>(() => f.Subject.SaveCaseRule(model));
            }

            [Fact]
            public async Task ConvertDetailsAndSaves()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                f.CharacteristicsValidator.Validate(Arg.Any<WorkflowCharacteristics>()).Returns(new ValidatedCharacteristics());
                var model = new SanityCheckCaseViewModel
                {
                    RuleOverview =
                    {
                        DisplayMessage = "Arthur",
                        RuleDescription = "A",
                        Notes = "La la land",
                        InformationOnly = true
                    },
                    CaseCharacteristics = new CaseCharacteristicsModel
                    {
                        Office = 1,
                        Jurisdiction = "AUS",
                        JurisdictionExclude = true
                    }
                };

                var data = await f.Subject.SaveCaseRule(model);

                var record = Db.Set<DataValidation>().Single();
                Assert.Equal(KnownFunctionalArea.Case, record.FunctionalArea);
                Assert.Equal(model.RuleOverview.DisplayMessage, record.DisplayMessage);
                Assert.Equal(model.RuleOverview.RuleDescription, record.RuleDescription);
                Assert.Equal(model.RuleOverview.Notes, record.Notes);
                Assert.Equal(model.RuleOverview.InformationOnly, record.IsWarning);

                Assert.Equal(model.CaseCharacteristics.Office, record.OfficeId);
                Assert.Equal(model.CaseCharacteristics.Jurisdiction, record.CountryCode);
                Assert.Equal(model.CaseCharacteristics.JurisdictionExclude, record.NotCountryCode);
                Assert.Equal(1, data.Id);
            }
        }

        public class UpdateCaseRuleMethod : FactBase
        {
            [Fact]
            public async Task PerformsMandatoryChecks()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.UpdateCaseRule(new SanityCheckCaseViewUpdateModel()));

                var model = new SanityCheckCaseViewUpdateModel { RuleOverview = { DisplayMessage = "Arthur" } };
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.UpdateCaseRule(model));
            }

            [Fact]
            public async Task VerifiesValidCombination()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                f.CharacteristicsValidator.Validate(Arg.Any<WorkflowCharacteristics>()).Returns(new ValidatedCharacteristics { PropertyType = new ValidatedCharacteristic(null, null, false) });
                var model = new SanityCheckCaseViewUpdateModel { RuleOverview = { DisplayMessage = "Arthur", RuleDescription = "A" } };

                await Assert.ThrowsAsync<Exception>(() => f.Subject.UpdateCaseRule(model));
            }

            [Fact]
            public async Task ConvertDetailsAndSaves()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                new DataValidation { FunctionalArea = KnownFunctionalArea.Case }.In(Db);
                f.CharacteristicsValidator.Validate(Arg.Any<WorkflowCharacteristics>()).Returns(new ValidatedCharacteristics());
                var model = new SanityCheckCaseViewUpdateModel
                {
                    ValidationId = 1,
                    RuleOverview =
                    {
                        DisplayMessage = "Arthur",
                        RuleDescription = "A",
                        Notes = "La la land",
                        InformationOnly = true
                    },
                    CaseCharacteristics = new CaseCharacteristicsModel
                    {
                        Office = 1,
                        Jurisdiction = "AUS",
                        JurisdictionExclude = true
                    }
                };

                var result = await f.Subject.UpdateCaseRule(model);

                var record = Db.Set<DataValidation>().Single();
                Assert.Equal(KnownFunctionalArea.Case, record.FunctionalArea);
                Assert.Equal(model.RuleOverview.DisplayMessage, record.DisplayMessage);
                Assert.Equal(model.RuleOverview.RuleDescription, record.RuleDescription);
                Assert.Equal(model.RuleOverview.Notes, record.Notes);
                Assert.Equal(model.RuleOverview.InformationOnly, record.IsWarning);

                Assert.Equal(model.CaseCharacteristics.Office, record.OfficeId);
                Assert.Equal(model.CaseCharacteristics.Jurisdiction, record.CountryCode);
                Assert.Equal(model.CaseCharacteristics.JurisdictionExclude, record.NotCountryCode);
                Assert.Equal(1, result.Id);
            }
        }
        public class UpdateNameRuleMethod : FactBase
        {
            [Fact]
            public async Task PerformsMandatoryChecks()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.UpdateNameRule(new SanityCheckNameViewUpdateModel()));

                var model = new SanityCheckNameViewUpdateModel { RuleOverview = { DisplayMessage = "A message" } };
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.UpdateNameRule(model));
            }

            [Fact]
            public async Task ConvertDetailsAndSaves()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                new DataValidation { FunctionalArea = KnownFunctionalArea.Name }.In(Db);
                var model = new SanityCheckNameViewUpdateModel
                {
                    ValidationId = 1,
                    RuleOverview =
                    {
                        DisplayMessage = "display message",
                        RuleDescription = "A",
                        Notes = "notes",
                        InformationOnly = true
                    },
                    NameCharacteristics = new SanityCheckNameViewModel.NameCharacteristicsModel()
                    {
                        Name = 10,
                        Category = 102,
                        IsSupplierOnly = true,
                        Jurisdiction = "AUS"
                    },
                    StandingInstruction = new StandingInstructionModel(),
                    Other = new OtherModel()
                };

                var data = await f.Subject.UpdateNameRule(model);

                var record = Db.Set<DataValidation>().Single();
                Assert.Equal(KnownFunctionalArea.Name, record.FunctionalArea);
                Assert.Equal(model.RuleOverview.DisplayMessage, record.DisplayMessage);
                Assert.Equal(model.RuleOverview.RuleDescription, record.RuleDescription);
                Assert.Equal(model.RuleOverview.Notes, record.Notes);
                Assert.Equal(model.RuleOverview.InformationOnly, record.IsWarning);

                Assert.Equal(model.NameCharacteristics.Name, record.NameId);
                Assert.Equal(model.NameCharacteristics.Jurisdiction, record.CountryCode);
                Assert.Equal(model.NameCharacteristics.IsSupplierOnly, record.SupplierFlag);
                Assert.Equal(model.NameCharacteristics.Category, record.Category);
                Assert.Equal(1, data.Id);
            }
        }
        public class SaveNameMethod : FactBase
        {
            [Fact]
            public async Task PerformsMandatoryChecks()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.SaveNameRule(new SanityCheckNameViewModel()));

                var model = new SanityCheckNameViewModel { RuleOverview = { DisplayMessage = "Arthur" } };
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.SaveNameRule(model));
            }

            [Fact]
            public async Task ConvertDetailsAndSaves()
            {
                var f = new SanityCheckMaintenanceControllerFixture(Db);
                var model = new SanityCheckNameViewModel
                {
                    RuleOverview =
                    {
                        DisplayMessage = "Arthur",
                        RuleDescription = "A",
                        Notes = "La la land",
                        InformationOnly = true
                    },
                    NameCharacteristics = new SanityCheckNameViewModel.NameCharacteristicsModel
                    {
                        Name = 10,
                        IsSupplierOnly = true,
                        Jurisdiction = "AUS"
                    }
                };

                var data = await f.Subject.SaveNameRule(model);

                var record = Db.Set<DataValidation>().Single();
                Assert.Equal(KnownFunctionalArea.Name, record.FunctionalArea);
                Assert.Equal(model.RuleOverview.DisplayMessage, record.DisplayMessage);
                Assert.Equal(model.RuleOverview.RuleDescription, record.RuleDescription);
                Assert.Equal(model.RuleOverview.Notes, record.Notes);
                Assert.Equal(model.RuleOverview.InformationOnly, record.IsWarning);

                Assert.Equal(model.NameCharacteristics.Name, record.NameId);
                Assert.Equal(model.NameCharacteristics.Jurisdiction, record.CountryCode);
                Assert.Equal(model.NameCharacteristics.IsSupplierOnly, record.SupplierFlag);
                Assert.Equal(1, data.Id);
            }
        }

        [Fact]
        public async Task GetViewDataCaseReturnsNullIfNoId()
        {
            var f = new SanityCheckMaintenanceControllerFixture(Db);
            var result = await f.Subject.GetViewDataCase(null);

            Assert.Null(result);
        }

        [Fact]
        public async Task GetViewDataCaseReturnsData()
        {
            var validationRule1 = new DataValidation { RuleDescription = "New rule 1", DisplayMessage = "A1" }.In(Db);
            var data = new CaseSanityCheckRuleModel { DataValidation = new CaseDataValidationModel(){RuleDescription =validationRule1.RuleDescription, DisplayMessage = validationRule1.DisplayMessage, Id = validationRule1.Id }, CaseDetails = new CaseRelatedDataModel { CaseType = new PicklistModel<int>(1, "A", "Sky") } };

            var f = new SanityCheckMaintenanceControllerFixture(Db);
            f.SanityCheckConfigurationService.GetCaseValidationRule(Arg.Any<int>())
             .Returns(data);

            var result = await f.Subject.GetViewDataCase(1);

            Assert.NotNull(result);
            Assert.Equal(1, result.DataValidation.Id);
            Assert.Equal(validationRule1.RuleDescription, result.DataValidation.RuleDescription);
            Assert.Equal(validationRule1.DisplayMessage, result.DataValidation.DisplayMessage);
            Assert.Equal("Sky", result.CaseDetails.CaseType.Value);
        }
    }

    public class SanityCheckMaintenanceControllerFixture : IFixture<SanityCheckMaintenanceController>
    {
        public SanityCheckMaintenanceControllerFixture(InMemoryDbContext db)
        {
            CharacteristicsValidator = Substitute.For<ICharacteristicsValidator>();
            SanityCheckConfigurationService = Substitute.For<ISanityCheckService>();
            Subject = new SanityCheckMaintenanceController(db, CharacteristicsValidator, SanityCheckConfigurationService);
        }

        public SanityCheckMaintenanceController Subject { get; }

        public ICharacteristicsValidator CharacteristicsValidator { get; }

        public ISanityCheckService SanityCheckConfigurationService { get; }
    }
}