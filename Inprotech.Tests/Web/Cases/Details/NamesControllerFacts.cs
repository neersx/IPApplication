using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Cases;
using Inprotech.Web.Cases.Details;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class NamesControllerFacts
    {
        public class GetCaseViewNamesMethod
        {
            readonly ICommonQueryService _queryService = Substitute.For<ICommonQueryService>();
            readonly ICaseViewNamesProvider _caseViewNamesProvider = Substitute.For<ICaseViewNamesProvider>();
            readonly ICaseEmailTemplateParametersResolver _caseEmailTemplateParametersResolver = Substitute.For<ICaseEmailTemplateParametersResolver>();
            readonly ICaseEmailTemplate _caseEmailTemplate = Substitute.For<ICaseEmailTemplate>();

            NamesController CreateSubject()
            {
                return new NamesController(_queryService, _caseViewNamesProvider, _caseEmailTemplateParametersResolver, _caseEmailTemplate);
            }

            [Fact]
            public async Task ShouldResolveParametersThenReturnsCaseEmailTemplate()
            {
                var caseId = Fixture.Integer();
                var nameType = Fixture.String();
                var parameters = new CaseNameEmailTemplateParameters
                {
                    CaseKey = caseId, NameType = nameType
                };
                var resolvedParameters = new CaseNameEmailTemplateParameters();

                var emailTemplate = new EmailTemplate();

                _caseEmailTemplateParametersResolver.Resolve(parameters).Returns(new[] {resolvedParameters});
                _caseEmailTemplate.ForCaseNames(Arg.Any<CaseNameEmailTemplateParameters[]>())
                                  .Returns(new[] {emailTemplate});

                var r = await CreateSubject().GetEmailTemplate(caseId, parameters, true);

                Assert.Equal(r.Single(), emailTemplate);

                _caseEmailTemplate.Received(1)
                                  .ForCaseNames(Arg.Is<CaseNameEmailTemplateParameters[]>(_ => _.SequenceEqual(new[] {resolvedParameters})))
                                  .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnsCaseEmailTemplate()
            {
                var caseId = Fixture.Integer();
                var nameType = Fixture.String();
                var sequence = Fixture.Integer();
                var parameters = new CaseNameEmailTemplateParameters
                {
                    CaseKey = caseId, NameType = nameType, Sequence = sequence
                };

                var emailTemplate = new EmailTemplate();

                _caseEmailTemplate.ForCaseNames(Arg.Any<CaseNameEmailTemplateParameters[]>())
                                  .Returns(new[] {emailTemplate});

                var r = await CreateSubject().GetEmailTemplate(caseId, parameters);

                Assert.Equal(r.Single(), emailTemplate);

                _caseEmailTemplate.Received(1)
                                  .ForCaseNames(Arg.Is<CaseNameEmailTemplateParameters[]>(_ => _.SequenceEqual(new[] {parameters})))
                                  .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnsCaseNames()
            {
                var caseId = Fixture.Integer();

                _queryService.GetSortedPage(Arg.Any<CaseViewName[]>(), Arg.Any<CommonQueryParameters>()).Returns(x => x[0]);
                _caseViewNamesProvider.GetNames(Arg.Any<int>(), Arg.Any<string[]>(), Arg.Any<int>())
                                      .Returns(new[]
                                      {
                                          new CaseViewName(),
                                          new CaseViewName(),
                                          new CaseViewName()
                                      });

                var r = await CreateSubject().GetCaseViewNames(caseId, Fixture.Integer());

                Assert.Equal(3, r.Data.Count());
            }

            [Fact]
            public async Task ShouldReturnsCaseNamesWithFilter()
            {
                var caseId = Fixture.Integer();
                var requestedNameType = Fixture.String();

                _queryService.GetSortedPage(Arg.Any<CaseViewName[]>(), Arg.Any<CommonQueryParameters>()).Returns(x => x[0]);
                _caseViewNamesProvider.GetNames(Arg.Any<int>(), Arg.Any<string[]>(), Arg.Any<int>())
                                      .Returns(new CaseViewName[0]);
                var filters = new NamesController.NameTypeFilterQuery {Keys = new[] {requestedNameType}};
                await CreateSubject().GetCaseViewNames(caseId, Fixture.Integer(), nameTypes: filters);

                _caseViewNamesProvider.Received(1)
                                      .GetNames(caseId, Arg.Is<string[]>(_ => _.Contains(requestedNameType)), Arg.Any<int>())
                                      .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }
}