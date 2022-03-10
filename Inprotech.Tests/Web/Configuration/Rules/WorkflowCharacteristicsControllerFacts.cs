using System;
using System.Globalization;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using ICharacteristicsValidator = Inprotech.Web.Configuration.Rules.ICharacteristicsValidator;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowCharacteristicsControllerFacts
    {
        public class GetDefaultDateOfLawMethod : FactBase
        {
            public class GetWorkflowCharacteristicsMethod : FactBase
            {
                [Fact]
                public void ReturnsEditProtectionBlockingFlags()
                {
                    var f = new WorkflowCharacteristicsControllerFixture(Db);
                    f.CharacteristicsService.GetValidCharacteristics(null)
                     .ReturnsForAnyArgs(new ValidatedCharacteristics());

                    var criteria = new CriteriaBuilder { LocalClientFlag = 1, RuleInUse = 1, Country = new CountryBuilder().Build() }.ForEventsEntriesRule().Build().In(Db);

                    var isEditProtectionBlockedByParentResult = Fixture.Boolean();
                    var isEditProtectionBlockedByDescendantsResult = Fixture.Boolean();

                    f.WorkflowPermissionHelper.WhenForAnyArgs(_ => _.GetEditProtectionLevelFlags(criteria, out isEditProtectionBlockedByParentResult, out isEditProtectionBlockedByDescendantsResult))
                     .Do(_ =>
                     {
                         _[1] = isEditProtectionBlockedByParentResult;
                         _[2] = isEditProtectionBlockedByDescendantsResult;
                     });

                    var result = f.Subject.GetWorkflowCharacteristics(criteria.Id);

                    Assert.Equal(isEditProtectionBlockedByParentResult, result.IsEditProtectionBlockedByParent);
                    Assert.Equal(isEditProtectionBlockedByDescendantsResult, result.IsEditProtectionBlockedByDescendants);
                }

                [Fact]
                public void ReturnsWorkflowCharacteristics()
                {
                    var f = new WorkflowCharacteristicsControllerFixture(Db);
                    f.CharacteristicsService.GetValidCharacteristics(null)
                     .ReturnsForAnyArgs(new ValidatedCharacteristics());

                    var examinationAction = new ActionBuilder { ActionType = 2 }.Build();

                    var criteria =
                        new CriteriaBuilder { LocalClientFlag = 1, RuleInUse = 1, Country = new CountryBuilder().Build() }
                            .WithOffice()
                            .WithAction(examinationAction)
                            .WithBasis()
                            .WithCaseCategory()
                            .WithCaseType()
                            .WithDateOfLaw()
                            .WithSubType()
                            .WithPropertyType()
                            .WithExaminationType().ForEventsEntriesRule().Build().In(Db);

                    var result = f.Subject.GetWorkflowCharacteristics(criteria.Id);
                    f.CharacteristicsService.Received(1)
                     .GetValidCharacteristics(Arg.Any<WorkflowCharacteristics>());

                    var args = f.GetValidCharacteristicsArgs[0];
                    Assert.Equal(criteria.Office.Id, args.Office);
                    Assert.Equal(criteria.Country.Id, args.Jurisdiction);
                    Assert.Equal(criteria.CaseTypeId, args.CaseType);
                    Assert.Equal(criteria.PropertyType.Code, args.PropertyType);
                    Assert.Equal(criteria.CaseCategoryId, args.CaseCategory);
                    Assert.Equal(criteria.SubType.Code, args.SubType);
                    Assert.Equal(criteria.Basis.Code, args.Basis);
                    Assert.Equal(criteria.Action.Code, args.Action);

                    Assert.Equal(criteria.Id, result.Id);
                    Assert.Equal(criteria.Description, result.CriteriaName);
                    Assert.Equal(criteria.IsLocalClient, result.IsLocalClient);
                    Assert.Equal(criteria.IsProtected, result.IsProtected);

                    Assert.Equal(criteria.DateOfLaw.Value.ToString(CultureInfo.InvariantCulture), result.DateOfLaw.Code);
                    Assert.Equal(criteria.DateOfLaw.Value.ToString("dd-MMM-yyyy"), result.DateOfLaw.Value);
                    Assert.Equal(criteria.Office.Id.ToString(), result.Office.Code);
                    Assert.Equal(criteria.Office.Name, result.Office.Value);
                    Assert.Equal(criteria.Country.Id, result.Jurisdiction.Code);
                    Assert.Equal(criteria.Country.Name, result.Jurisdiction.Value);

                    Assert.Equal(criteria.TableCodeId, result.ExaminationType.Key);
                    Assert.Null(result.RenewalType);
                }
            }

            [Fact]
            public void MakesDefaultDateOfLawCallPassingCaseIdAndAction()
            {
                var f = new WorkflowCharacteristicsControllerFixture(Db);
                var caseId = Fixture.Integer();
                var actionId = Fixture.String();
                var returnValue = new ValidatedCharacteristic(Fixture.String(), Fixture.String());
                f.DefaultDateOfLawCharacteristic.GetDefaultDateOfLaw(Arg.Any<int>(), Arg.Any<string>())
                 .ReturnsForAnyArgs(returnValue);

                var result = f.Subject.GetDefaultDateOfLaw(caseId, actionId);
                f.DefaultDateOfLawCharacteristic.Received(1).GetDefaultDateOfLaw(caseId, actionId);

                Assert.Equal(returnValue.Key, result.Key);
                Assert.Equal(returnValue.Value, result.Value);
                Assert.Equal(returnValue.IsValid, result.IsValid);
            }
        }

        public class WorkflowCharacteristicsControllerFixture : IFixture<WorkflowCharacteristicsController>
        {
            public WorkflowCharacteristicsControllerFixture(InMemoryDbContext db)
            {
                CharacteristicsValidator = Substitute.For<ICharacteristicsValidator>();
                CharacteristicsService = Substitute.For<ICharacteristicsService>();
                var characteristicsServiceIndex = Substitute.For<IIndex<string, ICharacteristicsService>>();
                characteristicsServiceIndex[CriteriaPurposeCodes.EventsAndEntries].Returns(CharacteristicsService);
                CharacteristicsService.WhenForAnyArgs(_ => _.GetValidCharacteristics(null)).Do(_ => GetValidCharacteristicsArgs = _.Args());
                WorkflowPermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                PreferredCultureResolver.Resolve().Returns("en");

                FormatDateOfLaw = Substitute.For<IFormatDateOfLaw>();
                FormatDateOfLaw.AsId(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString(CultureInfo.InvariantCulture));
                FormatDateOfLaw.Format(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString("dd-MMM-yyyy"));
                DefaultDateOfLawCharacteristic = Substitute.For<IValidatedDefaultDateOfLawCharacteristic>();
                Subject = new WorkflowCharacteristicsController(db, characteristicsServiceIndex, WorkflowPermissionHelper, PreferredCultureResolver, FormatDateOfLaw, DefaultDateOfLawCharacteristic);
            }
            public IValidatedDefaultDateOfLawCharacteristic DefaultDateOfLawCharacteristic { get; set; }

            public ICharacteristicsValidator CharacteristicsValidator { get; set; }

            public ICharacteristicsService CharacteristicsService { get; set; }

            public IWorkflowPermissionHelper WorkflowPermissionHelper { get; set; }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public IFormatDateOfLaw FormatDateOfLaw { get; set; }

            public dynamic GetValidCharacteristicsArgs { get; set; }
            public WorkflowCharacteristicsController Subject { get; }
        }
    }
}