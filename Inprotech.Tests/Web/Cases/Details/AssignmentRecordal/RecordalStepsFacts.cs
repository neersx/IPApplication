using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class RecordalStepsFacts
    {
        public class RecordalStepsFixture : IFixture<RecordalSteps>
        {
            public RecordalStepsFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                FormattedNameAddress = Substitute.For<IFormattedNameAddressTelecom>();
                StaticTranslator = Substitute.For<IStaticTranslator>();
                Subject = new RecordalSteps(db, FormattedNameAddress, PreferredCultureResolver, StaticTranslator);
            }

            public RecordalSteps Subject { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public IFormattedNameAddressTelecom FormattedNameAddress { get; }
            public IStaticTranslator StaticTranslator { get; }
        }

        public class GetRecordalSteps : FactBase
        {
            dynamic SetupData()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var relatedCase1 = new CaseBuilder { Irn = "def" }.Build().In(Db);
                var relatedCase2 = new CaseBuilder { Irn = "abc" }.Build().In(Db);
                var type1 = new RecordalType { Id = 1, RecordalTypeName = "Change of Owner" }.In(Db);
                var type2 = new RecordalType { Id = 2, RecordalTypeName = "Change of Address" }.In(Db);
                var step1 = new RecordalStep { CaseId = @case.Id, Id = 1, TypeId = type1.Id, RecordalType = type1, StepId = 2 }.In(Db);
                var step2 = new RecordalStep { CaseId = @case.Id, Id = 2, TypeId = type2.Id, RecordalType = type2, StepId = 1 }.In(Db);
                new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase1.Id, RelatedCase = relatedCase1, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 1, Status = "Not yet filed", RecordalStepSeq = 1}.In(Db);
                new RecordalAffectedCase { CaseId = @case.Id, Case = @case, RelatedCaseId = relatedCase2.Id, RelatedCase = relatedCase2, RecordalTypeNo = type1.Id, RecordalType = type1, SequenceNo = 3, Status = "Not yet filed", RecordalStepSeq = 1}.In(Db);

                var el1 = new Element { Id = 1, Code = "CURRENTNAME", Name = "CurrentName", EditAttribute = "MAN" }.In(Db);
                var el2 = new Element { Id = 2, Code = "NEWSTREETADDRESS", Name = "New Address", EditAttribute = "MAN" }.In(Db);
                var el3 = new Element { Id = 3, Code = "NEWNAME", Name = "New Name", EditAttribute = "MAN" }.In(Db);

                var n1 = new NameBuilder(Db).Build().In(Db);
                var n2 = new NameBuilder(Db).Build().In(Db);
                var a1 = new AddressBuilder().Build().In(Db);
                new RecordalElement { ElementId = el1.Id, Element = el1, Id = 1, EditAttribute = el1.EditAttribute, TypeId = type1.Id, RecordalType = type1 }.In(Db);
                new RecordalElement { ElementId = el2.Id, Element = el2, Id = 2, EditAttribute = el2.EditAttribute, TypeId = type1.Id, RecordalType = type1 }.In(Db);
                var nt1 = new NameTypeBuilder {ShowNameCode = 1}.Build().In(Db);
                var recordalElement = new RecordalElement { ElementId = el3.Id, Element = el3, Id = 3, TypeId = type2.Id, RecordalType = type2, EditAttribute = "DIS", ElementLabel = Fixture.String(), NameTypeCode = nt1.NameTypeCode}.In(Db);
                var stepElement1 = new RecordalStepElement { CaseId = @case.Id, EditAttribute = el1.EditAttribute, ElementId = el1.Id, Element = el1, ElementLabel = Fixture.String(), ElementValue = n1.Id + "," + n2.Id, RecordalStepId = step1.Id, NameTypeCode = nt1.NameTypeCode}.In(Db);
                var stepElement2 = new RecordalStepElement { CaseId = @case.Id, EditAttribute = el2.EditAttribute, ElementId = el2.Id, Element = el2, ElementLabel = Fixture.String(), ElementValue = a1.Id.ToString(), OtherValue = n1.Id.ToString(), RecordalStepId = step1.Id, NameTypeCode = nt1.NameTypeCode }.In(Db);

                return new
                {
                    @case,
                    step1,
                    step2,
                    recordalElement,
                    stepElement1,
                    stepElement2,
                    n1,
                    n2,
                    a1
                };
            }

            [Fact]
            public async Task ShouldReturnStepsDataInStepsOrder()
            {
                var f = new RecordalStepsFixture(Db);
                var data = SetupData();
                f.StaticTranslator.TranslateWithDefault(Arg.Any<string>(), Arg.Any<string[]>()).Returns("Step");
                var result = (CaseRecordalStep[])await f.Subject.GetRecordalSteps(data.@case.Id);
                Assert.Equal(2, result.Length);
                var firstStep = result.First();
                Assert.Equal(data.@case.Id, firstStep.CaseId);
                Assert.Equal(data.step2.StepId, firstStep.StepId);
                Assert.Equal("Step 1", firstStep.StepName);
                Assert.Equal(data.step2.RecordalType.Id, firstStep.RecordalType.Key);
                Assert.False(firstStep.IsAssigned);
                Assert.True(result.Last().IsAssigned);
            }

            [Fact]
            public async Task ShouldReturnSameRecordalTypeSteps()
            {
                var f = new RecordalStepsFixture(Db);
                var data = SetupData();
                var step = new RecordalStep { CaseId = data.@case.Id, Id = 3, TypeId = data.step1.TypeId, RecordalType = data.step1.RecordalType, StepId = 3 }.In(Db);
                f.StaticTranslator.TranslateWithDefault(Arg.Any<string>(), Arg.Any<string[]>()).Returns("Step");
                var result = (CaseRecordalStep[])await f.Subject.GetRecordalSteps(data.@case.Id);
                Assert.Equal(3, result.Length);
                var firstStep = result.First();
                Assert.Equal(data.@case.Id, firstStep.CaseId);
                Assert.Equal(data.step2.StepId, firstStep.StepId);
                Assert.Equal("Step 1", firstStep.StepName);
                Assert.Equal(data.step2.RecordalType.Id, firstStep.RecordalType.Key);
                Assert.Equal(step.StepId, result[2].StepId);
                Assert.Equal(step.RecordalType.Id, result[2].RecordalType.Key);
                Assert.False(firstStep.IsAssigned);
                Assert.True(result[1].IsAssigned);
                Assert.False(result[2].IsAssigned);
            }

            [Fact]
            public async Task ShouldThrowExceptionWhenStepNotFound()
            {
                var f = new RecordalStepsFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.GetRecordalStepElement(Fixture.Integer(), null));
            }

            [Fact]
            public async Task ShouldReturnDefaultElements()
            {
                var f = new RecordalStepsFixture(Db);
                var data = SetupData();
                var result = (CaseRecordalStepElement[])await f.Subject.GetRecordalStepElement(data.@case.Id, (RecordalStep)data.step2);
                Assert.Equal(1, result.Length);
                var firstStepElement = result.First();
                Assert.Equal(data.@case.Id, firstStepElement.CaseId);
                Assert.Equal(data.step2.Id, firstStepElement.Id);
                Assert.Equal(data.step2.StepId.ToString(), firstStepElement.StepId);
                Assert.Equal(data.recordalElement.ElementId, firstStepElement.ElementId);
                Assert.Equal(data.recordalElement.ElementLabel, firstStepElement.Label);
                Assert.Equal(data.recordalElement.EditAttribute, firstStepElement.EditAttribute);
                Assert.Equal(ElementType.Name, firstStepElement.Type);
                Assert.Null(firstStepElement.ValueId);
                Assert.Null(firstStepElement.OtherValueId);
                Assert.Null(firstStepElement.Value);
                Assert.Null(firstStepElement.OtherValue);
            }

            [Fact]
            public async Task ShouldReturnStepElements()
            {
                var f = new RecordalStepsFixture(Db);
                var data = SetupData();
                var formattedNames = new Dictionary<int, NameFormatted>
                {
                    {data.n1.Id, new NameFormatted {Name = "Owner 1", NameCode = "O1"}},
                    {data.n2.Id, new NameFormatted {Name = "Owner 2", NameCode = "O2"}}
                };
                var formattedAddresses = new Dictionary<int, AddressFormatted>
                {
                    {data.a1.Id, new AddressFormatted {Address = "Street Address"}}
                };
                f.FormattedNameAddress.GetFormatted(Arg.Any<int[]>()).Returns(formattedNames);
                f.FormattedNameAddress.GetAddressesFormatted(Arg.Any<int[]>()).Returns(formattedAddresses);

                var result = (CaseRecordalStepElement[])await f.Subject.GetRecordalStepElement(data.@case.Id, (RecordalStep)data.step1);
                Assert.Equal(2, result.Length);
                var firstStepElement = result.First();
                Assert.Equal(data.@case.Id, firstStepElement.CaseId);
                Assert.Equal(data.step1.Id, firstStepElement.Id);
                Assert.Equal(data.step1.StepId.ToString(), firstStepElement.StepId);
                Assert.Equal(data.stepElement1.ElementId, firstStepElement.ElementId);
                Assert.Equal(data.stepElement1.ElementLabel, firstStepElement.Label);
                Assert.Equal(data.stepElement1.EditAttribute, firstStepElement.EditAttribute);
                Assert.Equal(ElementType.Name, firstStepElement.Type);
                Assert.Equal(data.stepElement1.ElementValue, firstStepElement.ValueId);
                Assert.Equal(data.stepElement1.OtherValue, firstStepElement.OtherValueId);
                Assert.Equal("{O1} Owner 1; {O2} Owner 2", firstStepElement.Value);
                Assert.Null(firstStepElement.OtherValue);
                Assert.Equal(ElementType.StreetAddress, result[1].Type);
                Assert.Equal("Street Address", result[1].Value);
                Assert.Equal("{O1} Owner 1", result[1].OtherValue);
            }

            [Fact]
            public async Task ShouldReturnCurrentAddresses()
            {
                var f = new RecordalStepsFixture(Db);
                var postalAddress = new AddressBuilder().Build().In(Db);
                var streetAddress = new AddressBuilder().Build().In(Db);
                var @name = new NameBuilder(Db) {PostalAddress = postalAddress, StreetAddress = streetAddress}.Build().In(Db);
                var formattedNames = new Dictionary<int, NameFormatted>
                {
                    {
                        @name.Id,  new NameFormatted
                        {
                            NameId = @name.Id,
                            Name = Fixture.String(),
                            MainStreetAddressId = streetAddress.Id,
                            MainPostalAddressId = postalAddress.Id
                        }
                    }
                };
                var formattedAddresses = new Dictionary<int, AddressFormatted>
                {
                    {
                        streetAddress.Id,  new AddressFormatted
                        {
                            Id = streetAddress.Id,
                            Address = Fixture.String()
                        }
                    },
                    {
                        postalAddress.Id,  new AddressFormatted
                        {
                            Id = postalAddress.Id,
                            Address = Fixture.String()
                        }
                    }
                };

                f.FormattedNameAddress.GetFormatted(Arg.Any<int[]>()).Returns(formattedNames);
                f.FormattedNameAddress.GetAddressesFormatted(Arg.Any<int[]>()).Returns(formattedAddresses);

                var result = await f.Subject.GetCurrentAddress(@name.Id);
                Assert.NotNull(result);
                Assert.Equal(@name.Id, result.NamePicklist.Key);
                Assert.Equal(formattedNames[@name.Id].Name, result.NamePicklist.DisplayName);
                Assert.Equal(streetAddress.Id, result.StreetAddressPicklist.Id);
                Assert.Equal(formattedAddresses[streetAddress.Id].Address, result.StreetAddressPicklist.Address);
                Assert.Equal(postalAddress.Id, result.PostalAddressPicklist.Id);
                Assert.Equal(formattedAddresses[postalAddress.Id].Address, result.PostalAddressPicklist.Address);
            }
        }
    }
}
