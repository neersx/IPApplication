using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BatchEventUpdate;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Policing;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate
{
    public class SingleCaseUpdateFacts
    {
        public class UpdateMethod : FactBase
        {
            [Fact]
            public async Task DoesNotReturnInformativeValidationResultsAsErrorsOrWarnings()
            {
                var f = new SingleCaseUpdateFixture(Db).WithPositivePrereuisiteCheck()
                                                       .ReturnsValidationResult(
                                                                                new ValidationResult(
                                                                                                     "information",
                                                                                                     Severity.Information));

                var result = await f.Subject.Update(new CaseDataEntryTaskModel(), new Case(), new DataEntryTask());

                Assert.False(result.DataEntryTaskCompletionResult.HasErrors);
                Assert.False(result.DataEntryTaskCompletionResult.HasWarnings);
            }

            [Fact]
            public async Task IdentifiesErrorsAndWarnings()
            {
                var f = new SingleCaseUpdateFixture(Db).WithPositivePrereuisiteCheck()
                                                       .ReturnsValidationResults(
                                                                                 new[]
                                                                                 {
                                                                                     new ValidationResult("error"),
                                                                                     new ValidationResult(
                                                                                                          "warning",
                                                                                                          Severity.Warning)
                                                                                 });

                var result = await f.Subject.Update(new CaseDataEntryTaskModel(), new Case(), new DataEntryTask());

                Assert.True(result.DataEntryTaskCompletionResult.HasWarnings);
                Assert.True(result.DataEntryTaskCompletionResult.HasErrors);
            }

            [Fact]
            public async Task IdentifiesErrorsReturnedByPrerequisiteCheck()
            {
                var f = new SingleCaseUpdateFixture(Db);
                f.BatchDataEntryTaskPrerequisiteCheck.Run(null, null).ReturnsForAnyArgs(
                                                                                        new BatchDataEntryTaskPrerequisiteCheckResult
                                                                                            (
                                                                                             new DataEntryTaskPrerequisiteCheckResult
                                                                                                 (
                                                                                                  false,
                                                                                                  false,
                                                                                                  new CaseNameRestriction[
                                                                                                      0],
                                                                                                  new CaseName[0],
                                                                                                  true),
                                                                                             true));

                var result = await f.Subject.Update(new CaseDataEntryTaskModel(), new Case(), new DataEntryTask());

                Assert.True(result.DataEntryTaskCompletionResult.HasErrors);
            }

            [Fact]
            public async Task ReturnsTheBatchNumberReturnedByPolicingRequestProcessor()
            {
                const int batchNumber = 10;

                var f = new SingleCaseUpdateFixture(Db).WithPositivePrereuisiteCheck();

                f.DataEntryTaskDispatcher.ApplyChanges(null)
                 .ReturnsForAnyArgs(new DataEntryTaskCompletionResult(true, new DataEntryTaskHandlerResult[0]));

                f.PolicingRequestProcessor.Process(null, null).ReturnsForAnyArgs(batchNumber);

                var result = await f.Subject.Update(new CaseDataEntryTaskModel(), new Case(), new DataEntryTask());

                Assert.Equal(batchNumber, result.BatchNumberForImmediatePolicing);
            }

            [Fact]
            public async Task ReturnsTheValidationErrorsGeneratedWhenApplyingChanges()
            {
                var f = new SingleCaseUpdateFixture(Db).WithPositivePrereuisiteCheck()
                                                       .ReturnsValidationResult(new ValidationResult("error"));

                var result = await f.Subject.Update(new CaseDataEntryTaskModel(), new Case(), new DataEntryTask());

                Assert.True(result.DataEntryTaskCompletionResult.HasErrors);
                Assert.False(result.DataEntryTaskCompletionResult.HasWarnings);
            }

            [Fact]
            public async Task ReturnsTheValidationWarningsGeneratedWhenApplyingChanges()
            {
                var f = new SingleCaseUpdateFixture(Db).WithPositivePrereuisiteCheck()
                                                       .ReturnsValidationResult(
                                                                                new ValidationResult(
                                                                                                     "warning",
                                                                                                     Severity.Warning));

                var result = await f.Subject.Update(new CaseDataEntryTaskModel(), new Case(), new DataEntryTask());

                Assert.True(result.DataEntryTaskCompletionResult.HasWarnings);
                Assert.False(result.DataEntryTaskCompletionResult.HasErrors);
            }
        }
    }

    public class SingleCaseUpdateFixture : IFixture<SingleCaseUpdate>
    {
        public SingleCaseUpdateFixture(InMemoryDbContext db)
        {
            DataEntryTaskDispatcher = Substitute.For<IDataEntryTaskDispatcher>();
            DataEntryTaskHandlerInputFormatter = Substitute.For<IDataEntryTaskHandlerInputFormatter>();
            PolicingRequestProcessor = Substitute.For<IPolicingRequestProcessor>();
            BatchDataEntryTaskPrerequisiteCheck = Substitute.For<IBatchDataEntryTaskPrerequisiteCheck>();
            Subject = new SingleCaseUpdate(
                                           db,
                                           DataEntryTaskDispatcher,
                                           DataEntryTaskHandlerInputFormatter,
                                           PolicingRequestProcessor,
                                           BatchDataEntryTaskPrerequisiteCheck);
        }

        public IDataEntryTaskDispatcher DataEntryTaskDispatcher { get; set; }

        public IDataEntryTaskHandlerInputFormatter DataEntryTaskHandlerInputFormatter { get; set; }

        public IPolicingRequestProcessor PolicingRequestProcessor { get; set; }

        public IBatchDataEntryTaskPrerequisiteCheck BatchDataEntryTaskPrerequisiteCheck { get; set; }

        public SingleCaseUpdate Subject { get; }

        public SingleCaseUpdateFixture WithPositivePrereuisiteCheck()
        {
            BatchDataEntryTaskPrerequisiteCheck.Run(null, null)
                                               .ReturnsForAnyArgs(new BatchDataEntryTaskPrerequisiteCheckResult());

            return this;
        }

        public SingleCaseUpdateFixture ReturnsValidationResult(ValidationResult result)
        {
            return ReturnsValidationResults(new[] {result});
        }

        public SingleCaseUpdateFixture ReturnsValidationResults(ValidationResult[] results)
        {
            DataEntryTaskDispatcher.ApplyChanges(null)
                                   .ReturnsForAnyArgs(
                                                      new DataEntryTaskCompletionResult(
                                                                                        false,
                                                                                        new DataEntryTaskHandlerResult[0],
                                                                                        results));

            return this;
        }
    }
}