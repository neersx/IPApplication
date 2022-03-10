using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class DesignElementsFacts
    {
        public class DesignElementMethod : FactBase
        {
            [Fact]
            public void ReturnsElementDataInAscendingOrder()
            {
                var f = new DesignElementsFixture(Db);
                var data = SetupData();

                if (!(data.@case is Case @case)) return;
                var r = f.Subject.GetCaseDesignElements(@case.Id);
                var a = r.ToArray();
                Assert.Equal("345", a[1].FirmElementCaseRef);
                Assert.Equal("567", a[2].FirmElementCaseRef);
                Assert.Equal(a[0].Images.Count(), 1);
                Assert.Equal(a[1].Images.Count(), 0);
                Assert.Equal(a[2].Images.Count(), 2);
            }

            [Fact]
            public void ReturnsNoElementData()
            {
                var f = new DesignElementsFixture(Db);

                var @case = new Case();
                var r = f.Subject.GetCaseDesignElements(@case.Id);
                var a = r.ToArray();
                Assert.Null(a.FirstOrDefault());
            }

            dynamic SetupData()
            {
                var @case = new CaseBuilder
                {
                    Country = new CountryBuilder { Id = "ZZZ" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db)
                }.Build().In(Db);

                var d1 = new DesignElement(@case.Id, 0)
                {
                    ClientElementId = "ClientElement",
                    Description = "E2EDesign Element Desc",
                    FirmElementId = "567",
                    IsRenew = true,
                    OfficialElementId = "OfficialElement",
                    RegistrationNo = "RegNo"

                }.In(Db);

                var d2 = new DesignElement(@case.Id, 1)
                {
                    ClientElementId = Fixture.String("345"),
                    FirmElementId = Fixture.String("123"),
                    OfficialElementId = "OfficialElement",
                    RegistrationNo = "RegNo",
                    IsRenew = true
                }.In(Db);

                var d3 = new DesignElement(@case.Id, 0)
                {
                    ClientElementId = "ClientID",
                    Description = "E2EDesig new nElementDesc",
                    FirmElementId = "345",
                    IsRenew = true,
                    OfficialElementId = "OfficialElement12",
                    RegistrationNo = "RegNo"

                }.In(Db);

                new CaseImage(@case, Fixture.Integer(), Fixture.Short(), KnownImageTypes.Attachment) { FirmElementId = d1.FirmElementId }.In(Db);
                new CaseImage(@case, Fixture.Integer(), Fixture.Short(), KnownImageTypes.Attachment) { FirmElementId = d1.FirmElementId }.In(Db);
                new CaseImage(@case, Fixture.Integer(), Fixture.Short(), KnownImageTypes.Attachment) { FirmElementId = d2.FirmElementId }.In(Db);

                return new
                {
                    d1,
                    d2,
                    d3,
                    @case
                };
            }
        }

        public class ValidateDesignElementsMethod : FactBase
        {
            dynamic SetData()
            {
                var @case = new Case().In(Db);
                var firmElem = Fixture.String();
                var deElem = new DesignElement(@case.Id, 0) {FirmElementId = firmElem}.In(Db);
                var deElem2 = new DesignElement(@case.Id, 1) {FirmElementId = Fixture.String()}.In(Db);
                @case.CaseDesignElements.Add(deElem);
                @case.CaseDesignElements.Add(deElem2);

                return new
                {
                    @case,
                    deElem,
                    deElem2,
                    firmElem
                };
            }

            [Fact]
            public void ReturnsNoErrorsWhenNoFirmElemIsDuplicate()
            {
                var f = new DesignElementsFixture(Db);
                var data = SetData();

                var changedRows = new DesignElementData[]{};

                var newRow = new DesignElementData
                {
                    RowKey = "new_1",
                    Sequence = null,
                    FirmElementCaseRef = Fixture.String()
                };

                var validationErrors = f.Subject.ValidateDesignElements((Case)data.@case, newRow, changedRows).ToArray();
                Assert.Equal(0, validationErrors.Length);
            }

            [Fact]
            public void ReturnsValidationErrorsWhenFirmElemIsDuplicate()
            {
                var f = new DesignElementsFixture(Db);
                var data = SetData();

                var changedRows = new[]
                {
                    new DesignElementData
                    {
                        RowKey = "new_0",
                        Sequence = 2,
                        FirmElementCaseRef = Fixture.String()
                    },
                    new DesignElementData
                    {
                        RowKey = "1",
                        Sequence = 1,
                        FirmElementCaseRef = Fixture.String("Firm3")
                    }
                };

                var newRow = new DesignElementData
                {
                    RowKey = "new_1",
                    Sequence = null,
                    FirmElementCaseRef = data.firmElem
                };

                var validationErrors = f.Subject.ValidateDesignElements((Case)data.@case, newRow, changedRows).ToArray();
                Assert.Equal(1, validationErrors.Length);
                Assert.Equal(KnownCaseMaintenanceTopics.DesignElements, validationErrors[0].Topic);
                Assert.Equal(DesignElementsInputNames.FirmElementId, validationErrors[0].Field);
                Assert.Equal(newRow.RowKey, validationErrors[0].Id);
            }

            [Fact]
            public void ReturnsValidationErrorsWhenImagesAreDuplicate()
            {
                var f = new DesignElementsFixture(Db);
                var data = SetData();
                var @case = (Case) data.@case;
                var img1 = new Image().In(Db);
                var img2 = new Image().In(Db);
                var img3 = new Image().In(Db);
                var img4 = new Image().In(Db);
                var caseImage = new CaseImage(@case, img1.Id, 0, KnownImageTypes.TradeMark) {FirmElementId = data.deElem.FirmElementId}.In(Db);
                @case.CaseImages.Add(caseImage);
                var caseImage2 = new CaseImage(@case, img2.Id, 0, KnownImageTypes.TradeMark) {FirmElementId = data.deElem2.FirmElementId}.In(Db);
                @case.CaseImages.Add(caseImage2);

                var changedRows = new[]
                {
                    new DesignElementData
                    {
                        RowKey = "new_0",
                        FirmElementCaseRef = Fixture.String(),
                        Images = new []
                        {
                            new ImageModel { Key = img3.Id}
                        }
                    },
                    new DesignElementData
                    {
                        Sequence = 1,
                        Status = KnownModifyStatus.Delete,
                        FirmElementCaseRef = data.deElem2.FirmElementId
                    }
                };

                var newRow = new DesignElementData
                {
                    RowKey = "new_1",
                    FirmElementCaseRef = Fixture.String(),
                    Images = new []
                    {
                        new ImageModel { Key = img4.Id },
                        new ImageModel { Key = img3.Id },
                        new ImageModel { Key = img1.Id },
                        new ImageModel { Key = img2.Id }
                    }
                };

                var validationErrors = f.Subject.ValidateDesignElements(@case, newRow, changedRows).ToArray();
                Assert.Equal(1, validationErrors.Length);
                Assert.Equal(KnownCaseMaintenanceTopics.DesignElements, validationErrors[0].Topic);
                Assert.Equal(DesignElementsInputNames.ImageId, validationErrors[0].Field);
                Assert.Equal(newRow.RowKey, validationErrors[0].Id);
                var dupImages = (int[]) validationErrors[0].CustomData;
                Assert.Equal(2, dupImages.Length);
                Assert.True(dupImages.Contains(img1.Id));
                Assert.True(dupImages.Contains(img3.Id));
            }
        }

        public class DesignElementsFixture : IFixture<DesignElements>
        {

            public DesignElementsFixture(InMemoryDbContext db)
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new DesignElements(db, cultureResolver);
            }

            public DesignElements Subject { get; }

        }
    }
}
