using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Cases.Maintenance.Updaters;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Web.Cases.Maintenance.Updaters
{
    public class DesignElementsTopicUpdaterFacts : FactBase
    {
        [Fact]
        public void ShouldCreateDesignElements()
        {
            var f = new DesignElementsTopicUpdaterFixture();
            var @case = new Case().In(Db);
            var img1 = new Image().In(Db);
            var img2 = new Image().In(Db);
            var img3 = new Image().In(Db);
            var caseImage = new CaseImage(@case, img1.Id, 0, KnownImageTypes.TradeMark).In(Db);
            @case.CaseImages.Add(caseImage);

            var saveModel = new DesignElementSaveModel
            {
                Rows = new[]
                {
                    new DesignElementData
                    {
                        FirmElementCaseRef = Fixture.String("Firm"),
                        ClientElementCaseRef = Fixture.String(),
                        ElementDescription = Fixture.String(),
                        ElementOfficialNo = Fixture.String(),
                        RegistrationNo = Fixture.String(),
                        NoOfViews = Fixture.Short(10),
                        Renew = false,
                        StopRenewDate = Fixture.Date(),
                        Images = new[] {new ImageModel { Key = img1.Id }, new ImageModel { Key = img2.Id }, new ImageModel { Key = img3.Id }}
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            var model = saveModel.Rows[0];
            var de = @case.CaseDesignElements.First();
            Assert.Equal(1, @case.CaseDesignElements.Count);
            Assert.Equal(0, de.Sequence);
            Assert.Equal(model.FirmElementCaseRef, de.FirmElementId);
            Assert.Equal(model.ClientElementCaseRef, de.ClientElementId);
            Assert.Equal(model.ElementDescription, de.Description);
            Assert.Equal(model.RegistrationNo, de.RegistrationNo);
            Assert.Equal(model.Renew, de.IsRenew);
            Assert.Equal(model.StopRenewDate, de.StopRenewDate);
            Assert.Equal(model.NoOfViews, de.Typeface);
            var caseImages = @case.CaseImages.Where(x => x.FirmElementId == de.FirmElementId).OrderBy(_ => _.ImageSequence).ToArray();
            Assert.Equal(3, caseImages.Count());
            Assert.Equal(KnownImageTypes.Design, caseImages[1].ImageType);
            Assert.Equal(1, caseImages[1].ImageSequence);
            Assert.Equal(KnownImageTypes.Design, caseImages[2].ImageType);
        }

        [Fact]
        public void ShouldEditDesignElements()
        {
            var f = new DesignElementsTopicUpdaterFixture();
            var @case = new Case().In(Db);
            var img1 = new Image().In(Db);
            var img2 = new Image().In(Db);
            var img3 = new Image().In(Db);
            var deElem = new DesignElement(@case.Id, 0) {FirmElementId = Fixture.String()}.In(Db);
            @case.CaseDesignElements.Add(deElem);
            var caseImage = new CaseImage(@case, img1.Id, 0, KnownImageTypes.TradeMark) {FirmElementId = deElem.FirmElementId}.In(Db);
            @case.CaseImages.Add(caseImage);

            var saveModel = new DesignElementSaveModel
            {
                Rows = new[]
                {
                    new DesignElementData
                    {
                        Sequence = 0,
                        FirmElementCaseRef = Fixture.String("Firm"),
                        ClientElementCaseRef = Fixture.String(),
                        ElementDescription = Fixture.String(),
                        ElementOfficialNo = Fixture.String(),
                        RegistrationNo = Fixture.String(),
                        NoOfViews = Fixture.Short(10),
                        Renew = false,
                        StopRenewDate = Fixture.Date(),
                        Images = new[] {new ImageModel { Key = img2.Id }, new ImageModel { Key = img3.Id }}
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            var model = saveModel.Rows[0];
            var de = @case.CaseDesignElements.First();
            Assert.Equal(@case.CaseDesignElements.Count, 1);
            Assert.Equal(model.FirmElementCaseRef, de.FirmElementId);
            Assert.Equal(model.ClientElementCaseRef, de.ClientElementId);
            Assert.Equal(model.ElementDescription, de.Description);
            Assert.Equal(model.RegistrationNo, de.RegistrationNo);
            Assert.Equal(model.Renew, de.IsRenew);
            Assert.Equal(model.StopRenewDate, de.StopRenewDate);
            Assert.Equal(model.NoOfViews, de.Typeface);
            var caseImages = @case.CaseImages.Where(x => x.FirmElementId == de.FirmElementId);
            Assert.Equal(2, caseImages.Count());
            Assert.Null(caseImage.FirmElementId);
        }

        [Fact]
        public void ShouldDeleteDesignElements()
        {
            var f = new DesignElementsTopicUpdaterFixture();
            var @case = new Case().In(Db);
            var img1 = new Image().In(Db);
            var img2 = new Image().In(Db);
            var deElem = new DesignElement(@case.Id, 0) {FirmElementId = Fixture.String()}.In(Db);
            @case.CaseDesignElements.Add(deElem);
            var caseImage = new CaseImage(@case, img1.Id, 0, KnownImageTypes.TradeMark) {FirmElementId = deElem.FirmElementId}.In(Db);
            var caseImage2 = new CaseImage(@case, img2.Id, 0, KnownImageTypes.TradeMark) {FirmElementId = deElem.FirmElementId}.In(Db);
            @case.CaseImages.Add(caseImage);
            @case.CaseImages.Add(caseImage2);

            var saveModel = new DesignElementSaveModel
            {
                Rows = new[]
                {
                    new DesignElementData
                    {
                        Sequence = 0,
                        FirmElementCaseRef = Fixture.String("Firm"),
                        ClientElementCaseRef = Fixture.String(),
                        ElementDescription = Fixture.String(),
                        ElementOfficialNo = Fixture.String(),
                        RegistrationNo = Fixture.String(),
                        NoOfViews = Fixture.Short(10),
                        Renew = false,
                        StopRenewDate = Fixture.Date(),
                        Images = new[] {new ImageModel { Key = img1.Id }, new ImageModel { Key = img2.Id }},
                        Status = KnownModifyStatus.Delete
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            Assert.Equal(0, @case.CaseDesignElements.Count);
            Assert.Null(caseImage.FirmElementId);
            Assert.Null(caseImage2.FirmElementId);
        }

        public class DesignElementsTopicUpdaterFixture : IFixture<DesignElementsTopicUpdater>
        {
            public DesignElementsTopicUpdaterFixture()
            {
                TransactionRecordal = Substitute.For<ITransactionRecordal>();
                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                ComponentResolver = Substitute.For<IComponentResolver>();
                Subject = new DesignElementsTopicUpdater(TransactionRecordal, SiteConfiguration, ComponentResolver);
            }

            public DesignElementsTopicUpdater Subject { get; }
            public ITransactionRecordal TransactionRecordal { get; set; }
            public ISiteConfiguration SiteConfiguration { get; set; }
            public IComponentResolver ComponentResolver { get; set; }
        }
    }
}
