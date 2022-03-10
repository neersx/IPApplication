using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Web.BatchEventUpdate.Miscellaneous;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.DataEntryTaskHandlersFacts
{
    public class WhenMustGenerateDocumentsExistInDataEntryTask : FactBase
    {
        [Fact]
        public void Must_generate_documents_should_be_queued()
        {
            var fixture = new BatchEventDataEntryTaskHandlerFixture(Db);

            fixture.ExistingDataEntryTask.DocumentRequirements.Add(
                                                                   new DocumentRequirementBuilder
                                                                   {
                                                                       Criteria = fixture.ExistingDataEntryTask.Criteria,
                                                                       DataEntryTask = fixture.ExistingDataEntryTask,
                                                                       Document = DocumentBuilder.ForCases().Build().In(Db),
                                                                       IsMandatory = true
                                                                   }.Build().In(Db));

            var result = fixture.Subject.ApplyChanges(fixture.ExistingCase, fixture.ExistingDataEntryTask,
                                                      fixture.CaseUpdateModel);

            var documents = fixture.ExistingDataEntryTask.DocumentRequirements.Select(dr => dr.Document).ToArray();

            fixture.EventDetailUpdateHandler.Received()
                   .ApplyChanges(
                                 Arg.Any<Case>(),
                                 Arg.Any<DataEntryTask>(),
                                 Arg.Any<string>(),
                                 Arg.Any<int?>(),
                                 Arg.Any<DateTime>(),
                                 Arg.Any<AvailableEventModel[]>(),
                                 Arg.Is<Document[]>(x => x.SequenceEqual(documents)));
        }
    }
}