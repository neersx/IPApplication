using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.SanityCheck;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.DataValidation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.SanityCheck
{
    public class SanityCheckConfigurationControllerFact : FactBase
    {
        readonly SanityCheckConfigurationController _subject;
        readonly ISanityCheckService service;
        readonly ITaskSecurityProvider taskSecurityProvider;

        public SanityCheckConfigurationControllerFact()
        {
            service = Substitute.For<ISanityCheckService>();
            taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            _subject = new SanityCheckConfigurationController(service, Db, taskSecurityProvider);
        }

        [Theory]
        [InlineData(nameof(SanityCheckConfigurationController.GetViewDataCase), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify)]
        [InlineData(nameof(SanityCheckConfigurationController.GetViewDataCase), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
        [InlineData(nameof(SanityCheckConfigurationController.GetViewDataName), ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Create)]
        [InlineData(nameof(SanityCheckConfigurationController.GetViewDataName), ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify)]
        [InlineData(nameof(SanityCheckConfigurationController.CaseSearch), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
        [InlineData(nameof(SanityCheckConfigurationController.CaseSearch), ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify)]
        [InlineData(nameof(SanityCheckConfigurationController.NameSearch), ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Create)]
        [InlineData(nameof(SanityCheckConfigurationController.NameSearch), ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify)]
        public void ShouldHaveCorrectRequireAccessAttribute(string method, ApplicationTask task, ApplicationTaskAccessLevel applicationTaskAccessLevel)
        {
            var methodInfo = typeof(SanityCheckConfigurationController).GetMethod(method);
            Assert.NotNull(methodInfo);
            var attributes = methodInfo.GetCustomAttributes<RequiresAccessToAttribute>().ToArray();
            Assert.NotEmpty(attributes);
            Assert.Single(attributes.Where(a => a.Task == task && a.Level == applicationTaskAccessLevel));
        }

        [Fact]
        public async Task ThrowsExceptionWhileRetrivingData()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await _subject.CaseSearch(null, new CommonQueryParameters()); });

            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await _subject.CaseSearch(null, null); });
        }

        [Fact]
        public async Task RetrievesDataValidationsCases()
        {
            var validationRule1 = new DataValidation { RuleDescription = "New rule 1", DisplayMessage = "A1" }.In(Db);
            var validationRule2 = new DataValidation { RuleDescription = "New rule 2", DisplayMessage = "A2" }.In(Db);
            var data = new List<CaseSanityCheckRuleModel>
                {
                    new() { DataValidation = new CaseDataValidationModel(){RuleDescription =validationRule1.RuleDescription, DisplayMessage = validationRule1.DisplayMessage, Id = validationRule1.Id}, CaseDetails = new CaseRelatedDataModel { CaseType = new PicklistModel<int>(1, "A", "Sky") } },
                    new() { DataValidation = new CaseDataValidationModel(){RuleDescription =validationRule2.RuleDescription, DisplayMessage = validationRule2.DisplayMessage, Id = validationRule2.Id}, CaseDetails = new CaseRelatedDataModel { Category = new PicklistModel<string>("B", "B", "Limit") } }
                }
                .AsAsyncQueryable();

            service.GetCaseValidationRules(Arg.Any<SanityCheckCaseViewModel>(), Arg.Any<CommonQueryParameters>()).Returns(data);

            var result = await _subject.CaseSearch(new SanityCheckCaseViewModel(), new CommonQueryParameters()) as IEnumerable<dynamic>;
            var resultData = result?.ToList();

            Assert.NotNull(resultData);
            Assert.Equal(2, resultData.Count);

            Assert.Equal(1, resultData.First().DataValidation.Id);
            Assert.Equal(validationRule1.RuleDescription, resultData.First().DataValidation.RuleDescription);
            Assert.Equal("Sky", resultData.First().CaseDetails.CaseType.Value);

            Assert.Equal(2, resultData.Last().DataValidation.Id);
            Assert.Equal(validationRule2.RuleDescription, resultData.Last().DataValidation.RuleDescription);
            Assert.Equal("Limit", resultData.Last().CaseDetails.Category.Value);
        }

        [Fact]
        public async Task RetrievesDataValidationsNames()
        {
            var validationRule1 = new DataValidation { RuleDescription = "New rule 1", DisplayMessage = "A1" }.In(Db);
            var validationRule2 = new DataValidation { RuleDescription = "New rule 2", DisplayMessage = "A2" }.In(Db);
            var data = new List<dynamic>
                {
                    new { DataValidation = validationRule1 },
                    new { DataValidation = validationRule2 }
                }
                .AsAsyncQueryable();

            service.GetNameValidationRules(Arg.Any<SanityCheckNameViewModel>(), Arg.Any<CommonQueryParameters>()).Returns(data);

            var result = await _subject.NameSearch(new SanityCheckNameViewModel(), new CommonQueryParameters()) as IEnumerable<dynamic>;
            var resultData = result?.ToList();

            Assert.NotNull(resultData);
            Assert.Equal(2, resultData.Count);

            Assert.Equal(1, resultData.First().DataValidation.Id);
            Assert.Equal(validationRule1.RuleDescription, resultData.First().DataValidation.RuleDescription);

            Assert.Equal(2, resultData.Last().DataValidation.Id);
            Assert.Equal(validationRule2.RuleDescription, resultData.Last().DataValidation.RuleDescription);
        }

        [Fact]
        public void ShouldReturnViewData()
        {
            taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Delete).Returns(true);
            taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify).Returns(true);
            var r = _subject.GetViewDataCase();
            Assert.True(r.canDeleteForCase);
            Assert.True(r.canUpdateForName);
            Assert.False(r.canDeleteForName);
        }
    }
}