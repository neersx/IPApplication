using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class RecordalStepsUpdaterFacts
    {
        public class RecordalStepsUpdaterFixture : IFixture<RecordalStepsUpdater>
        {
            public RecordalStepsUpdaterFixture(InMemoryDbContext db)
            {
                Subject = new RecordalStepsUpdater(db);
            }

            public RecordalStepsUpdater Subject { get; set; }
        }

        public class ValidateRecordalSteps : FactBase
        {
            [Fact]
            public void ShouldReturnNullWhenNoRecordalSteps()
            {
                var f = new RecordalStepsUpdaterFixture(Db);
                var result = f.Subject.Validate(new CaseRecordalStep[] { });
                Assert.Equal(0, result.Count());
            }

            [Fact]
            public void ShouldReturnNullWhenAllStepsForDelete()
            {
                var f = new RecordalStepsUpdaterFixture(Db);
                var steps = new[] {new CaseRecordalStep {CaseId = Fixture.Integer(), Status = KnownModifyStatus.Delete}};
                var result = f.Subject.Validate(steps);
                Assert.Equal(0, result.Count());
            }

            [Fact]
            public void ShouldReturnErrorWhenRecordalTypeIsNull()
            {
                var f = new RecordalStepsUpdaterFixture(Db);
                var steps = new[] {new CaseRecordalStep {CaseId = Fixture.Integer(), Status = KnownModifyStatus.Add, Id = 1, StepName = "Step 1"}};
                var result = f.Subject.Validate(steps).ToArray();
                Assert.Equal(1, result.Length);
                Assert.Equal("field.errors.recordal.recordalTypeNull", result[0].Message);
                Assert.Equal("Step 1", result[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorWhenStepElementsNotThere()
            {
                var rt = new RecordalType { Id = 1, RecordalTypeName = Fixture.String() }.In(Db);
                var f = new RecordalStepsUpdaterFixture(Db);
                var steps = new[] { new CaseRecordalStep { CaseId = 1, Status = KnownModifyStatus.Add, Id = 2, StepName = "Step 2", RecordalType = new RecordalTypePicklistItem {Key = rt.Id, Value = rt.RecordalTypeName} } };
                var result = f.Subject.Validate(steps).ToArray();
                Assert.Equal(1, result.Length);
                Assert.Equal("field.errors.recordal.required", result[0].Message);
                Assert.Equal("Step 2", result[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorWhenStepElementsDoesNotHaveMandatoryFields()
            {
                var rt = new RecordalType { Id = 1, RecordalTypeName = Fixture.String() }.In(Db);
                var rt1 = new RecordalType { Id = 2, RecordalTypeName = Fixture.String() }.In(Db);
                var f = new RecordalStepsUpdaterFixture(Db);
                var steps = new[]
                {
                    new CaseRecordalStep
                    {
                        CaseId = 1, 
                        Status = KnownModifyStatus.Add, 
                        Id = 2, StepName = "Step 2", 
                        RecordalType = new RecordalTypePicklistItem {Key = rt.Id, Value = rt.RecordalTypeName},
                        CaseRecordalStepElements = new []
                        {
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Mandatory, Type = ElementType.Name},
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Display, Type = ElementType.StreetAddress}
                        }
                    },
                    new CaseRecordalStep
                    {
                        CaseId = 1, 
                        Status = KnownModifyStatus.Edit, 
                        Id = 3, StepName = "Step 3", 
                        RecordalType = new RecordalTypePicklistItem {Key = rt1.Id, Value = rt1.RecordalTypeName},
                        CaseRecordalStepElements = new []
                        {
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Mandatory, Type = ElementType.StreetAddress, NamePicklist = new []{new Name {Key = Fixture.Integer()}}}
                        }
                    }
                };
                var result = f.Subject.Validate(steps).ToArray();
                Assert.Equal(2, result.Count());
                Assert.Equal("field.errors.recordal.required", result[0].Message);
                Assert.Equal("Step 2", result[0].Field);
                Assert.Equal("field.errors.recordal.required", result[1].Message);
                Assert.Equal("Step 3", result[1].Field);
            }
        }

        public class SubmitRecordalSteps : FactBase
        {
            [Fact]
            public async Task ShouldAddSteps()
            {
                var rt = new RecordalType { Id = 1, RecordalTypeName = Fixture.String() }.In(Db);
                var f = new RecordalStepsUpdaterFixture(Db);
                var names = new[] {new Name {Key = Fixture.Integer()}, new Name {Key = Fixture.Integer()}};
                var steps = new[]
                {
                    new CaseRecordalStep
                    {
                        CaseId = 1, 
                        Status = KnownModifyStatus.Add, 
                        Id = 1, 
                        StepName = "Step 2",
                        StepId = 1,
                        RecordalType = new RecordalTypePicklistItem {Key = rt.Id, Value = rt.RecordalTypeName},
                        CaseRecordalStepElements = new []
                        {
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Mandatory, Type = ElementType.Name, NamePicklist = names, ElementId=1},
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Display, Type = ElementType.StreetAddress, ElementId = 2}
                        }
                    }
                };
                await f.Subject.SubmitRecordalStep(steps);
                var recordalStep = Db.Set<RecordalStep>().FirstOrDefault();
                Assert.NotNull(recordalStep);
                Assert.Equal(1, recordalStep.CaseId);
                Assert.Equal(1, recordalStep.Id);
                Assert.Equal(1, recordalStep.StepId);
                Assert.Equal(rt.Id, recordalStep.TypeId);
                var recordalStepElements = Db.Set<RecordalStepElement>().Where(_ => _.RecordalStepId == 1);
                Assert.Equal(2, recordalStepElements.Count());
                var firstElement = recordalStepElements.First();
                Assert.Equal(KnownRecordalEditAttributes.Mandatory, firstElement.EditAttribute);
                Assert.Equal(1, firstElement.ElementId);
                Assert.Equal(string.Join(",", names.Select(_ => _.Key)), firstElement.ElementValue);
                var lastElement = recordalStepElements.Last();
                Assert.Equal(KnownRecordalEditAttributes.Display, lastElement.EditAttribute);
                Assert.Equal(2, lastElement.ElementId);
                Assert.Null(lastElement.ElementValue);
            }

            [Fact]
            public async Task ShouldDeleteStep()
            {
                var rt = new RecordalType { Id = 1, RecordalTypeName = Fixture.String() }.In(Db);
                new RecordalStep {CaseId = 1, Id = 1, RecordalType = rt, TypeId = rt.Id, StepId = 1}.In(Db);
                var f = new RecordalStepsUpdaterFixture(Db);
                var steps = new[]
                {
                    new CaseRecordalStep
                    {
                        CaseId = 1, 
                        Status = KnownModifyStatus.Delete, 
                        Id = 1, 
                        StepId = 1,
                        RecordalType = new RecordalTypePicklistItem {Key = rt.Id, Value = rt.RecordalTypeName}
                    }
                };
                await f.Subject.SubmitRecordalStep(steps);
                Assert.Equal(0, Db.Set<RecordalStep>().Count());
            }

            [Fact]
            public async Task ShouldEditSteps()
            {
                var rt = new RecordalType { Id = 1, RecordalTypeName = Fixture.String() }.In(Db);
                var rt1 = new RecordalType {Id = 2, RecordalTypeName = Fixture.String()}.In(Db);
                new RecordalStep {CaseId = 1, Id = 1, RecordalType = rt, TypeId = rt.Id, StepId = 1}.In(Db);
                new RecordalStepElement {CaseId = 1, ElementId = 1, RecordalStepId = 1, ElementValue = "1", EditAttribute = KnownRecordalEditAttributes.Display}.In(Db);
                var f = new RecordalStepsUpdaterFixture(Db);
                var names = new[] {new Name {Key = Fixture.Integer()}, new Name {Key = Fixture.Integer()}};
                var steps = new[]
                {
                    new CaseRecordalStep
                    {
                        CaseId = 1, 
                        Status = KnownModifyStatus.Edit, 
                        Id = 1, 
                        StepName = "Step 2",
                        StepId = 1,
                        RecordalType = new RecordalTypePicklistItem {Key = rt1.Id, Value = rt1.RecordalTypeName},
                        CaseRecordalStepElements = new []
                        {
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Mandatory, Type = ElementType.Name, NamePicklist = names, ElementId=2},
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Display, Type = ElementType.StreetAddress, ElementId = 3}
                        }
                    }
                };
                await f.Subject.SubmitRecordalStep(steps);
                var recordalStep = Db.Set<RecordalStep>().FirstOrDefault();
                Assert.NotNull(recordalStep);
                Assert.Equal(rt1.Id, recordalStep.TypeId);
                var recordalStepElements = Db.Set<RecordalStepElement>().Where(_ => _.RecordalStepId == 1);
                Assert.Equal(2, recordalStepElements.Count());
                var firstElement = recordalStepElements.First();
                Assert.Equal(KnownRecordalEditAttributes.Mandatory, firstElement.EditAttribute);
                Assert.Equal(2, firstElement.ElementId);
                Assert.Equal(string.Join(",", names.Select(_ => _.Key)), firstElement.ElementValue);
                var lastElement = recordalStepElements.Last();
                Assert.Equal(KnownRecordalEditAttributes.Display, lastElement.EditAttribute);
                Assert.Equal(3, lastElement.ElementId);
                Assert.Null(lastElement.ElementValue);
            }

            [Fact]
            public async Task ShouldUpdateStepElements()
            {
                var rt = new RecordalType { Id = 1, RecordalTypeName = Fixture.String() }.In(Db);
                new RecordalStep {CaseId = 1, Id = 1, RecordalType = rt, TypeId = rt.Id, StepId = 1}.In(Db);
                new RecordalStep {CaseId = 1, Id = 2, RecordalType = rt, TypeId = rt.Id, StepId = 2}.In(Db);
                new RecordalStepElement {CaseId = 1, ElementId = 1, RecordalStepId = 1, ElementValue = "1", EditAttribute = KnownRecordalEditAttributes.Mandatory}.In(Db);
                new RecordalStepElement {CaseId = 1, ElementId = 2, RecordalStepId = 2, ElementValue = "1", OtherValue = "1", EditAttribute = KnownRecordalEditAttributes.Display}.In(Db);
                var f = new RecordalStepsUpdaterFixture(Db);
                var names = new[] {new Name {Key = Fixture.Integer()}, new Name {Key = Fixture.Integer()}};
                var address = new AddressPicklistItem
                {
                    Id = Fixture.Integer(),
                    Address = Fixture.String()
                };
                var steps = new[]
                {
                    new CaseRecordalStep
                    {
                        CaseId = 1, 
                        Status = null, 
                        Id = 1, 
                        StepName = "Step 1",
                        StepId = 1,
                        RecordalType = new RecordalTypePicklistItem {Key = rt.Id, Value = rt.RecordalTypeName},
                        CaseRecordalStepElements = new []
                        {
                            new CaseRecordalStepElement {CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Mandatory, Type = ElementType.Name, NamePicklist = names, ElementId=1, Status = KnownModifyStatus.Edit}
                        }
                    },
                    new CaseRecordalStep
                    {
                        CaseId = 1, 
                        Status = null, 
                        Id = 2, 
                        StepName = "Step 2",
                        StepId = 2,
                        RecordalType = new RecordalTypePicklistItem {Key = rt.Id, Value = rt.RecordalTypeName},
                        CaseRecordalStepElements = new []
                        {
                            new CaseRecordalStepElement
                            {
                                CaseId = 1, EditAttribute = KnownRecordalEditAttributes.Display, Type = ElementType.StreetAddress, ElementId = 2, Status = KnownModifyStatus.Edit, 
                                NamePicklist = new[] {names[0]}, 
                                AddressPicklist = address
                            }
                        }
                    }
                };
                await f.Subject.SubmitRecordalStep(steps);
                var recordalStep = Db.Set<RecordalStep>().FirstOrDefault();
                Assert.NotNull(recordalStep);
                var firstElement = Db.Set<RecordalStepElement>().First(_ => _.RecordalStepId == 1);
                Assert.Equal(1, firstElement.ElementId);
                Assert.Equal(string.Join(",", names.Select(_ => _.Key)), firstElement.ElementValue);
                var secondElement = Db.Set<RecordalStepElement>().First(_ => _.RecordalStepId == 2);
                Assert.Equal(2, secondElement.ElementId);
                Assert.Equal(names[0].Key.ToString(), secondElement.OtherValue);
                Assert.Equal(address.Id.ToString(), secondElement.ElementValue);
            }
        }
    }
}
