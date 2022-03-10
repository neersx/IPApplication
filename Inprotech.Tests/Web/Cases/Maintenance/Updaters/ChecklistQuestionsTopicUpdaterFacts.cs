using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Accounting.Charge;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Cases.Maintenance.Updaters;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.ChargeGeneration;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance.Updaters
{
    public class ChecklistQuestionsTopicUpdaterFacts
    {
        public class UpdateDataMethod : FactBase
        {
            [Fact]
            public void ShouldAddChecklistAndAnswers()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = true,
                            YesUpdateEventId = Fixture.Integer(),
                            NoAnswer = false,
                            TextValue = Fixture.String(),
                            CountValue = Fixture.Integer()
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                var topicModel = JObject.FromObject(saveModel);
                fixture.Subject.UpdateData(topicModel, null, @case);
                Assert.Equal(1, @case.CaseChecklists.Count);
                Assert.Equal(saveModel.Rows[0].YesAnswer, @case.CaseChecklists.SingleOrDefault(v => v.CaseId == @case.Id)?.YesNoAnswer == 1m);
                Assert.Equal(saveModel.Rows[0].NoAnswer, @case.CaseChecklists.SingleOrDefault(v => v.CaseId == @case.Id)?.YesNoAnswer == 0m);
                Assert.Equal(saveModel.Rows[0].TextValue, @case.CaseChecklists.SingleOrDefault(v => v.CaseId == @case.Id)?.ChecklistText);
                Assert.Equal(saveModel.Rows[0].CountValue, @case.CaseChecklists.SingleOrDefault(v => v.CaseId == @case.Id)?.CountAnswer);
            }

            [Fact]
            public void ShouldUpdateTheEnteredDeadlineWhenConfiguredTo()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var caseEvent = new CaseEventBuilder().BuildForCase(@case).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData()
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = true,
                            TextValue = Fixture.String(),
                            CountValue = Fixture.Integer(),
                            PeriodTypeKey = KnownPeriodTypes.Days,
                            YesUpdateEventId = caseEvent.EventNo
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                var topicModel = JObject.FromObject(saveModel);
                fixture.Subject.UpdateData(topicModel, null, @case);
                Assert.Equal(saveModel.Rows[0].CountValue, @case.CaseEvents.SingleOrDefault(v => v.EventNo == caseEvent.EventNo && v.Cycle == caseEvent.Cycle)?.EnteredDeadline);
                Assert.Null(@case.CaseChecklists.SingleOrDefault(v => v.CaseId == @case.Id)?.CountAnswer);
            }

            [Fact]
            public void ShouldUpdateExistCaseEvent()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var caseEvent = new CaseEventBuilder().BuildForCase(@case).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData()
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = true,
                            YesUpdateEventId = caseEvent.EventNo,
                            DateValue = Fixture.Today().AddDays(3)
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                var topicModel = JObject.FromObject(saveModel);
                fixture.Subject.UpdateData(topicModel, null, @case);
                fixture.EventUpdater.Received(1).AddOrUpdateEvent(@case, caseEvent.EventNo, saveModel.Rows[0].DateValue, caseEvent.Cycle);
            }

            [Fact]
            public void ShouldAddCaseEventIfNotExisting()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var eventId = Fixture.Integer();
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData()
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = true,
                            YesUpdateEventId = eventId,
                            DateValue = Fixture.Today().AddDays(3)
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                var topicModel = JObject.FromObject(saveModel);
                fixture.Subject.UpdateData(topicModel, null, @case);
                fixture.EventUpdater.Received(1).AddOrUpdateEvent(@case, eventId, saveModel.Rows[0].DateValue, 1);
            }

            [Fact]
            public void ShouldUpdateCaseEventDueDateWhenConfiguredTo()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var caseEvent = new CaseEventBuilder().BuildForCase(@case).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData()
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = true,
                            YesUpdateEventId = caseEvent.EventNo,
                            YesDueDateFlag = true,
                            DateValue = Fixture.Today().AddDays(3)
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                var topicModel = JObject.FromObject(saveModel);
                fixture.Subject.UpdateData(topicModel, null, @case);
                fixture.EventUpdater.Received(1).AddOrUpdateDueDateEvent(@case, caseEvent.EventNo, saveModel.Rows[0].DateValue, caseEvent.Cycle);
            }

            [Fact]
            public void ShouldRemoveCaseEventDueDateWhenConfiguredTo()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var caseEvent = new CaseEventBuilder().BuildForCase(@case).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData()
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = true,
                            YesUpdateEventId = caseEvent.EventNo,
                            YesDueDateFlag = true,
                            DateValue = null
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                var topicModel = JObject.FromObject(saveModel);
                fixture.Subject.UpdateData(topicModel, null, @case);
                fixture.EventUpdater.Received(1).RemoveCaseEventDate(caseEvent, true);
            }

            [Fact]
            public void ShouldUpdateYesAnswerDateWhenYesAndNoNotTickedButThereIsADate()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var caseEvent = new CaseEventBuilder().BuildForCase(@case).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData()
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = false,
                            NoAnswer = false,
                            YesUpdateEventId = caseEvent.EventNo,
                            YesDueDateFlag = true,
                            DateValue = Fixture.Today().AddDays(3)
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                var topicModel = JObject.FromObject(saveModel);
                fixture.Subject.UpdateData(topicModel, null, @case);
                fixture.EventUpdater.Received(1).AddOrUpdateDueDateEvent(@case, caseEvent.EventNo, saveModel.Rows[0].DateValue, caseEvent.Cycle);
            }

            [Fact]
            public void ShouldRegenerateDocuments()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var subject = Substitute.For<ChecklistQuestionsTopicUpdater>(fixture.EventUpdater, Db, fixture.DocumentGenerator, fixture.ChargeGenerator, fixture.RatesCommand, fixture.TransactionRecordal, fixture.SiteConfiguration, fixture.ComponentResolver);
                var @case = new CaseBuilder().Build().In(Db);
                new CaseEventBuilder().BuildForCase(@case).In(Db);
                var checklistCriteriaKey = Fixture.Integer();
                var documentOne = new DocumentBuilder().Build().In(Db);
                var question = new QuestionBuilder().Build(Fixture.Short()).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = Fixture.Short(),
                            RegenerateDocuments = true
                        }
                    },
                    ChecklistTypeId = Fixture.Short()
                };
                new ChecklistLetter
                {
                    CriteriaId = checklistCriteriaKey,
                    LetterNo = documentOne.Id,
                    QuestionId = question.Id,
                    RequiredAnswer = (decimal?)KnownRequiredAnswer.Yes
                }.In(Db);
                var topicModel = JObject.FromObject(saveModel);
                subject.UpdateData(topicModel, null, @case);
                subject.Received(1).ProcessDocument(saveModel, @case, saveModel.Rows[0].QuestionId, KnownRequiredAnswer.Yes);
            }
        }

        public class ProcessDocuments : FactBase
        {
            [Fact]
            public void ShouldGenerateMandatoryLetters()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var checklistId = Fixture.Short();
                var checklistCriteriaKey = Fixture.Integer();
                var documentOne = new DocumentBuilder().Build().In(Db);
                new ChecklistLetter
                {
                    CriteriaId = checklistCriteriaKey,
                    LetterNo = documentOne.Id
                }.In(Db);
                var documentTwo = new DocumentBuilder().Build().In(Db);
                new ChecklistLetter
                {
                    CriteriaId = checklistCriteriaKey,
                    LetterNo = documentTwo.Id
                }.In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = false,
                            NoAnswer = false,
                            YesDueDateFlag = true,
                            DateValue = Fixture.Today().AddDays(3)
                        }
                    },
                    ChecklistTypeId = checklistId,
                    ChecklistCriteriaKey = checklistCriteriaKey
                };
                fixture.Subject.ProcessMandatoryDocuments(saveModel, @case, false);

                fixture.DocumentGenerator.Received(1).QueueChecklistQuestionDocument(@case, saveModel.ChecklistTypeId, saveModel.ChecklistCriteriaKey, null, documentOne);
                fixture.DocumentGenerator.Received(1).QueueChecklistQuestionDocument(@case, saveModel.ChecklistTypeId, saveModel.ChecklistCriteriaKey, null, documentTwo);
            }

            [Fact]
            public void ShouldGenerateSelectedLetters()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var checklistId = Fixture.Short();
                var checklistCriteriaKey = Fixture.Integer();
                var documentOne = new DocumentBuilder().Build().In(Db);
                new ChecklistLetter
                {
                    CriteriaId = checklistCriteriaKey,
                    LetterNo = documentOne.Id
                }.In(Db);
                var documentTwo = new DocumentBuilder().Build().In(Db);
                new ChecklistLetter
                {
                    CriteriaId = checklistCriteriaKey,
                    LetterNo = documentTwo.Id
                }.In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = Fixture.Short(),
                            YesAnswer = false,
                            NoAnswer = false,
                            YesDueDateFlag = true,
                            DateValue = Fixture.Today().AddDays(3)
                        }
                    },
                    ChecklistTypeId = checklistId,
                    ChecklistCriteriaKey = checklistCriteriaKey,
                    GeneralDocs = new []
                    {
                        new ChecklistDocuments
                        {
                            DocumentId = documentTwo.Id,
                            RegenerateGeneralDoc = true
                        }
                    }
                };
                fixture.Subject.ProcessMandatoryDocuments(saveModel, @case, true);

                fixture.DocumentGenerator.Received(1).QueueChecklistQuestionDocument(@case, saveModel.ChecklistTypeId, saveModel.ChecklistCriteriaKey, null, documentTwo);
            }

            [Fact]
            public void ShouldGenerateNonMandatoryLetters()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var checklistId = Fixture.Short();
                var checklistCriteriaKey = Fixture.Integer();
                var documentOne = new DocumentBuilder().Build().In(Db);
                var question = new QuestionBuilder().Build(Fixture.Short()).In(Db);
                new ChecklistLetter
                {
                    CriteriaId = checklistCriteriaKey,
                    LetterNo = documentOne.Id,
                    QuestionId = question.Id,
                    RequiredAnswer = (decimal?)KnownRequiredAnswer.Yes
                }.In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = question.Id,
                            YesAnswer = true,
                            NoAnswer = false,
                            YesDueDateFlag = true,
                            DateValue = Fixture.Today().AddDays(3)
                        }
                    },
                    ChecklistTypeId = checklistId,
                    ChecklistCriteriaKey = checklistCriteriaKey
                };
                fixture.Subject.ProcessDocument(saveModel, @case, question.Id, KnownRequiredAnswer.Yes);

                fixture.DocumentGenerator.Received(1).QueueChecklistQuestionDocument(@case, saveModel.ChecklistTypeId, saveModel.ChecklistCriteriaKey, question.Id, documentOne);
            }
        }

        public class ProcessChargesMethod : FactBase
        {
            [Fact]
            public void ShouldGenerateChargeWhenRateFound()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var checklistId = Fixture.Short();
                var checklistCriteriaKey = Fixture.Integer();
                var yesRateId = Fixture.Short();
                var noRateId = Fixture.Short();
                var question = new QuestionBuilder().Build(Fixture.Short()).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = question.Id,
                            YesAnswer = true,
                            NoAnswer = false,
                            YesRateId = yesRateId,
                            NoRateId = noRateId
                        }
                    },
                    ChecklistTypeId = checklistId,
                    ChecklistCriteriaKey = checklistCriteriaKey
                };
                var returnRates = new List<BestChargeRates> {new BestChargeRates {RateId = Fixture.Integer(), RateTypeId = null}};
                fixture.RatesCommand.GetRates(@case.Id, Arg.Any<int?>()).Returns(returnRates);
                fixture.Subject.ProcessCharges(saveModel.Rows[0], @case, saveModel, false);

                fixture.ChargeGenerator.Received(1).QueueChecklistQuestionCharge(@case, saveModel.ChecklistTypeId, saveModel.ChecklistCriteriaKey, question.Id, returnRates[0], saveModel.Rows[0]);
            }

            [Fact]
            public void ShouldNotGenerateChargeWhenBestRateNotFound()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var checklistId = Fixture.Short();
                var checklistCriteriaKey = Fixture.Integer();
                var yesRateId = Fixture.Short();
                var noRateId = Fixture.Short();
                var question = new QuestionBuilder().Build(Fixture.Short()).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = question.Id,
                            YesAnswer = true,
                            NoAnswer = false,
                            YesRateId = yesRateId,
                            NoRateId = noRateId
                        }
                    },
                    ChecklistTypeId = checklistId,
                    ChecklistCriteriaKey = checklistCriteriaKey
                };
                var returnRates = new List<BestChargeRates>();
                fixture.RatesCommand.GetRates(@case.Id, Arg.Any<int?>()).Returns(returnRates);
                fixture.Subject.ProcessCharges(saveModel.Rows[0], @case, saveModel, false);

                fixture.ChargeGenerator.Received(0).QueueChecklistQuestionCharge(@case, saveModel.ChecklistTypeId, saveModel.ChecklistCriteriaKey, question.Id, Arg.Any<int>(), saveModel.Rows[0]);
            }

            [Fact]
            public void ShouldRegenerateCharges()
            {
                var fixture = new ChecklistQuestionsTopicUpdaterFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var checklistId = Fixture.Short();
                var checklistCriteriaKey = Fixture.Integer();
                var yesRateTypeId = Fixture.Integer();
                var noRateTypeId = Fixture.Integer();
                var question = new QuestionBuilder().Build(Fixture.Short()).In(Db);
                var saveModel = new ChecklistQuestionsSaveModel
                {
                    Rows = new[]
                    {
                        new ChecklistQuestionData
                        {
                            QuestionId = question.Id,
                            YesRateId = yesRateTypeId,
                            NoRateId = noRateTypeId,
                            RegenerateCharges = true,
                            NoAnswer = true
                        }
                    },
                    ChecklistTypeId = checklistId,
                    ChecklistCriteriaKey = checklistCriteriaKey
                };
                var returnYesRates = new List<BestChargeRates> {new BestChargeRates {RateId = Fixture.Integer(), RateTypeId = yesRateTypeId}};
                var returnNoRates = new List<BestChargeRates> {new BestChargeRates {RateId = Fixture.Integer(), RateTypeId = noRateTypeId}};
                fixture.RatesCommand.GetRates(@case.Id, yesRateTypeId).Returns(returnYesRates);
                fixture.RatesCommand.GetRates(@case.Id, noRateTypeId).Returns(returnNoRates);
                fixture.Subject.ProcessCharges(saveModel.Rows[0], @case, saveModel, true);

                fixture.ChargeGenerator.Received(1).QueueChecklistQuestionCharge(@case, saveModel.ChecklistTypeId, saveModel.ChecklistCriteriaKey, question.Id, returnNoRates[0], saveModel.Rows[0]);
            }
        }
    }

    public class ChecklistQuestionsTopicUpdaterFixture : IFixture<ChecklistQuestionsTopicUpdater>
    {
        public ChecklistQuestionsTopicUpdaterFixture(IDbContext db)
        {
            EventUpdater = Substitute.For<IEventUpdater>();
            DocumentGenerator = Substitute.For<IDocumentGenerator>();
            ChargeGenerator = Substitute.For<IChargeGenerator>();
            RatesCommand = Substitute.For<IRatesCommand>();

            TransactionRecordal = Substitute.For<ITransactionRecordal>();
            SiteConfiguration = Substitute.For<ISiteConfiguration>();
            ComponentResolver = Substitute.For<IComponentResolver>();
            Subject = new ChecklistQuestionsTopicUpdater(EventUpdater, db, DocumentGenerator, ChargeGenerator, RatesCommand, TransactionRecordal, SiteConfiguration, ComponentResolver);
        }

        public ChecklistQuestionsTopicUpdater Subject { get; }
        public IEventUpdater EventUpdater { get; set; }
        public IDocumentGenerator DocumentGenerator { get; set; }
        public IChargeGenerator ChargeGenerator { get; set; }
        public IRatesCommand RatesCommand { get; set; }
        public ITransactionRecordal TransactionRecordal { get; set; }
        public ISiteConfiguration SiteConfiguration { get; set; }
        public IComponentResolver ComponentResolver { get; set; }
    }

}
