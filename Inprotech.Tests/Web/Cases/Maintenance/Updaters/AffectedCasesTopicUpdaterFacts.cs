using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Cases.Maintenance.Updaters;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using Newtonsoft.Json.Linq;
using NSubstitute;
using System.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance.Updaters
{
    public class AffectedCasesTopicUpdaterFacts : FactBase
    {
        dynamic SetupData()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var relatedCase1 = new CaseBuilder { Irn = "def" }.Build().In(Db);
            var relatedCase2 = new CaseBuilder { Irn = "abc" }.Build().In(Db);
            var type1 = new RecordalType { Id = 1, RecordalTypeName = "Change of Owner" }.In(Db);
            var type2 = new RecordalType { Id = 2, RecordalTypeName = "Change of Address" }.In(Db);
            var step1 = new RecordalStep { CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 1 }.In(Db);
            var step2 = new RecordalStep { CaseId = @case.Id, Id = 2, TypeId = type2.Id, RecordalType = type2, StepId = 2 }.In(Db);
            new RecordalStep { CaseId = @case.Id, Id = 3, TypeId = type2.Id, RecordalType = type2, StepId = 3 }.In(Db);
            var recordalAffectedCase1 = new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase1.Id, RelatedCase = relatedCase1, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 1, Status = AffectedCaseStatus.NotYetFiled, RecordalStepSeq = step1.Id }.In(Db);
            var recordalAffectedCase2 = new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase1.Id, RelatedCase = relatedCase1, RecordalTypeNo = type2.Id, RecordalType = type2, SequenceNo = 2, Status = AffectedCaseStatus.NotYetFiled, RecordalStepSeq = step2.Id }.In(Db);
            var recordalAffectedCase3 = new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase2.Id, RelatedCase = relatedCase2, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 3, Status = AffectedCaseStatus.NotYetFiled, RecordalStepSeq = step1.Id }.In(Db);

            return new
            {
                @case,
                relatedCase1,
                relatedCase2,
                recordalAffectedCase1,
                recordalAffectedCase2,
                recordalAffectedCase3,
                type1
            };
        }
        [Fact]
        public void ShouldCreateNewStepForAffectedCasesIfNewStepIsTrue()
        {
            var f = new AffectedCasesTopicUpdaterFixture(Db);
            var data = SetupData();
            var saveModel = new
            {
                rows = new dynamic[]
                {
                    new
                    {
                    rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                    step1 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                        step2 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                        step3 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^" + "^",
                        step1 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^" + "^",
                        step2 = true
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, data.@case);
            var relatedCase1 = Db.Set<Case>().SingleOrDefault(_ => _.Irn == "def");
            var relatedCase2 = Db.Set<Case>().SingleOrDefault(_ => _.Irn == "abc");
            var updatedAffectedCases1 = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId == relatedCase1.Id).ToArray();
            var updatedAffectedCases2 = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId == relatedCase2.Id).ToArray();
            Assert.Equal(3, updatedAffectedCases1.Length);
            Assert.Equal(2, updatedAffectedCases2.Length);
        }

        [Fact]
        public void ShouldAddRelatedCaseWhenNotExistWhileAddingNewSteps()
        {
            var f = new AffectedCasesTopicUpdaterFixture(Db);
            var data = SetupData();
            var country = new CountryBuilder().Build().In(Db);
            new RecordalAffectedCase {CaseId = data.@case.Id, CountryId = country.Id, OfficialNumber = "11", RecordalStepSeq = 1, RecordalType = data.type1, RecordalTypeNo = ((RecordalType) data.type1).Id}.In(Db);
            var saveModel = new
            {
                rows = new dynamic[]
                {
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^^",
                        step1 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^^",
                        step2 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^^" + country.Id + "^" + "11",
                        step1 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^^" + country.Id + "^" + "11",
                        step2 = true
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, data.@case);
            Assert.NotNull(Db.Set<RecordalAffectedCase>().FirstOrDefault(_ => _.CountryId == country.Id));
            f.Helper.Received(1).AddRelatedCase(data.@case, data.relatedCase2, null, null, Arg.Any<CaseRelation>(),Arg.Any<CaseRelation>(), Arg.Any<int>());
            f.Helper.Received(1).AddRelatedCase(data.@case, null, country.Id, "11", Arg.Any<CaseRelation>(),Arg.Any<CaseRelation>(), Arg.Any<int>());
        }

        [Fact]
        public void ShouldAddNewOwners()
        {
            var f = new AffectedCasesTopicUpdaterFixture(Db);
            var data = SetupData();
            var country = new CountryBuilder().Build().In(Db);
            new RecordalAffectedCase {CaseId = data.@case.Id, CountryId = country.Id, OfficialNumber = "11", RecordalStepSeq = 1, RecordalType = data.type1, RecordalTypeNo = ((RecordalType) data.type1).Id}.In(Db);
            var element = new Element {Code = KnownRecordalElementValues.NewName, Id = 1}.In(Db);
            new RecordalStepElement {CaseId = data.@case.Id, EditAttribute = KnownRecordalEditAttributes.Mandatory, Element = element, RecordalStepId = 2, NameTypeCode = KnownNameTypes.Owner, ElementValue = "1,2"}.In(Db);
            var saveModel = new
            {
                rows = new dynamic[]
                { 
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^^",
                        step1 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^^",
                        step2 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^^" + country.Id + "^" + "11",
                        step1 = true
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, data.@case);
            f.Helper.Received(1).AddNewOwners(Arg.Any<Case>(), "1,2");
        }

        [Fact]
        public void ShouldRemoveNewOwners()
        {
            var f = new AffectedCasesTopicUpdaterFixture(Db);
            var data = SetupData();
            var element = new Element {Code = KnownRecordalElementValues.NewName, Id = 1}.In(Db);
            new RecordalStepElement {CaseId = data.@case.Id, EditAttribute = KnownRecordalEditAttributes.Mandatory, Element = element, RecordalStepId = 1, NameTypeCode = KnownNameTypes.Owner, ElementValue = "1,2"}.In(Db);
            var saveModel = new
            {
                rows = new dynamic[]
                {
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                        step1 = false
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^" + "^",
                        step1 = false
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, data.@case);
            f.Helper.Received(2).RemoveNewOwners(Arg.Any<Case>(), "1,2");
        }

        [Fact]
        public void ShouldRemoveStepsForAffectedCasesIfStepIsFalse()
        {
            var f = new AffectedCasesTopicUpdaterFixture(Db);
            var data = SetupData();
            var saveModel = new
            {
                rows = new dynamic[]
                {
                    new
                    {
                    rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                    step1 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                        step2 = false
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^" + "^",
                        step1 = false
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, data.@case);
            var relatedCase1 = Db.Set<Case>().SingleOrDefault(_ => _.Irn == "def");
            var relatedCase2 = Db.Set<Case>().SingleOrDefault(_ => _.Irn == "abc");
            var updatedAffectedCases1 = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId == relatedCase1.Id).ToArray();
            var updatedAffectedCases2 = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId == relatedCase2.Id);
            Assert.Equal(1, updatedAffectedCases1.Length);
            Assert.False(updatedAffectedCases2.Any());
        }

        [Fact]
        public void ShouldRemoveRelatedCasesIfAllRelatedStepsAreFalse()
        {
            var f = new AffectedCasesTopicUpdaterFixture(Db);
            var data = SetupData();
            var saveModel = new
            {
                rows = new dynamic[]
                {
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                        step1 = true
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase1.Id + "^" + "^",
                        step2 = false
                    },
                    new
                    {
                        rowKey = data.@case.Id + "^" + data.relatedCase2.Id + "^" + "^",
                        step1 = false
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, data.@case);
            f.Helper.DidNotReceive().RemoveRelatedCase(data.@case, data.relatedCase1, string.Empty, string.Empty, Arg.Any<CaseRelation>(), Arg.Any<CaseRelation>());
            f.Helper.Received(1).RemoveRelatedCase(data.@case, data.relatedCase2, string.Empty, string.Empty, Arg.Any<CaseRelation>(), Arg.Any<CaseRelation>());
        }

        public class AffectedCasesTopicUpdaterFixture : IFixture<AffectedCasesTopicUpdater>
        {
            public AffectedCasesTopicUpdaterFixture(InMemoryDbContext db)
            {
                Helper = Substitute.For<IAssignmentRecordalHelper>();
                Subject = new AffectedCasesTopicUpdater(db, Helper);
            }

            public AffectedCasesTopicUpdater Subject { get; }
            public IAssignmentRecordalHelper Helper { get; }
        }
    }
}
