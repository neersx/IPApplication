using System.Linq;
using System.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class EventCategoryPicklistMaintenanceFacts : FactBase
    {
        public class SaveMethod : FactBase
        {
            readonly ILastInternalCodeGenerator _lastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

            [Fact]
            public void AddNewEventCategory()
            {
                var newImage = new Image(Fixture.Integer()) {ImageData = Fixture.RandomBytes(1)}.In(Db);
                var newImageDetail = new ImageDetail(newImage.Id) {ImageDescription = Fixture.String(), ContentType = Fixture.String(), ImageStatus = ProtectedTableCode.EventCategoryImageStatus}.In(Db);

                var s = new EventCategoryPicklistMaintenance(Db, _lastInternalCodeGenerator);

                var newEventCategory = new EventCategory(Fixture.Short(), Fixture.String(), Fixture.String(), newImage.ImageData, newImageDetail.ImageDescription, newImageDetail.ImageId);
                s.Save(newEventCategory, Operation.Add);

                _lastInternalCodeGenerator.Received(1).GenerateLastInternalCode(KnownInternalCodeTable.EventCategory);
                Assert.True(Db.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Any(v => v.Name == newEventCategory.Name));
            }

            [Fact]
            public void ChecksDescriptionLength()
            {
                var existingImage = new Image(Fixture.Integer()) {ImageData = Fixture.RandomBytes(1)}.In(Db);
                var existingImageDetail = new ImageDetail(existingImage.Id) {ImageDescription = Fixture.String(), ContentType = Fixture.String(), ImageStatus = ProtectedTableCode.EventCategoryImageStatus}.In(Db);
                new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short()) {Description = Fixture.String(), Name = Fixture.String()}.In(Db);

                var s = new EventCategoryPicklistMaintenance(Db, _lastInternalCodeGenerator);

                const string longDescription = @"uj54u8jgjogtjreioioretgj80453j80gretijog45j09g453jijogjrfewikikofewrikofewrikoferwkioifefkewiofkikofrewkoifekrwiofkerwofkreowfkreokfwokrowekrforewkf439090k90kgbjnbrnbbiontirtiortgijogtijpogrteijportgetgrpggrtrtgertgekortgekokkortgeogkortekortgkrtgekogtek5";
                var newEventCategory = new EventCategory(Fixture.Short(), Fixture.String(), longDescription, existingImage.ImageData, existingImageDetail.ImageDescription, existingImageDetail.ImageId);
                var r = s.Save(newEventCategory, Operation.Add);

                Assert.Equal(r.Errors[0].Message, "The value must not be greater than 254 characters.");
            }

            [Fact]
            public void ChecksNameLength()
            {
                var existingImage = new Image(Fixture.Integer()) {ImageData = Fixture.RandomBytes(1)}.In(Db);
                var existingImageDetail = new ImageDetail(existingImage.Id) {ImageDescription = Fixture.String(), ContentType = Fixture.String(), ImageStatus = ProtectedTableCode.EventCategoryImageStatus}.In(Db);
                new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short()) {Description = Fixture.String(), Name = Fixture.String()}.In(Db);

                var s = new EventCategoryPicklistMaintenance(Db, _lastInternalCodeGenerator);

                const string longName = @"uj54u8jgjogtjreioioretgj80453j80gretijog45j09g453jijog";
                var newEventCategory = new EventCategory(Fixture.Short(), longName, Fixture.String(), existingImage.ImageData, existingImageDetail.ImageDescription, existingImageDetail.ImageId);
                var r = s.Save(newEventCategory, Operation.Add);

                Assert.Equal(r.Errors[0].Message, "The value must not be greater than 50 characters.");
            }

            [Fact]
            public void MustHaveUniqueName()
            {
                var existingImage = new Image(Fixture.Integer()) {ImageData = Fixture.RandomBytes(1)}.In(Db);
                var existingImageDetail = new ImageDetail(existingImage.Id) {ImageDescription = Fixture.String(), ContentType = Fixture.String(), ImageStatus = ProtectedTableCode.EventCategoryImageStatus}.In(Db);
                var existingEventCategory = new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short()) {Description = Fixture.String(), Name = Fixture.String()}.In(Db);

                var s = new EventCategoryPicklistMaintenance(Db, _lastInternalCodeGenerator);

                var newEventCategory = new EventCategory(Fixture.Short(), existingEventCategory.Name, Fixture.String(), existingImage.ImageData, existingImageDetail.ImageDescription, existingImageDetail.ImageId);
                var r = s.Save(newEventCategory, Operation.Add);

                _lastInternalCodeGenerator.DidNotReceive().GenerateLastInternalCode(KnownInternalCodeTable.EventCategory);
                Assert.Equal(r.Errors[0].Message, "field.errors.notunique");
            }

            [Fact]
            public void UpdateEventCategory()
            {
                var existingImage = new Image(Fixture.Integer()) {ImageData = Fixture.RandomBytes(1)}.In(Db);
                var existingImageDetail = new ImageDetail(existingImage.Id) {ImageDescription = Fixture.String(), ContentType = Fixture.String(), ImageStatus = ProtectedTableCode.EventCategoryImageStatus}.In(Db);
                var existingEventCategory = new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short()) {Description = Fixture.String(), Name = Fixture.String()}.In(Db);

                var s = new EventCategoryPicklistMaintenance(Db, _lastInternalCodeGenerator);

                var updatedEventCategory = new EventCategory(existingEventCategory.Id, Fixture.String(), Fixture.String(), existingImage.ImageData, existingImageDetail.ImageDescription, existingImageDetail.ImageId);
                s.Save(updatedEventCategory, Operation.Update);

                var savedEventCategory = Db.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Single(v => v.Id == existingEventCategory.Id);

                _lastInternalCodeGenerator.DidNotReceive().GenerateLastInternalCode(KnownInternalCodeTable.EventCategory);
                Assert.Equal(savedEventCategory.ImageId, existingImage.Id);
                Assert.Equal(savedEventCategory.Description, updatedEventCategory.Description);
                Assert.Equal(savedEventCategory.Name, updatedEventCategory.Name);
            }
        }

        public class DeleteMethod : FactBase
        {
            readonly ILastInternalCodeGenerator _lastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

            [Fact]
            public void OnlyDeletesMatchingItem()
            {
                var existingId = Fixture.Short();
                new InprotechKaizen.Model.Cases.Events.EventCategory(existingId).In(Db);
                new InprotechKaizen.Model.Cases.Events.EventCategory((short) (existingId + 1)).In(Db);
                new InprotechKaizen.Model.Cases.Events.EventCategory((short) (existingId + 2)).In(Db);
                var s = new EventCategoryPicklistMaintenance(Db, _lastInternalCodeGenerator);
                var r = s.Delete(existingId);
                Assert.Equal("success", r.Result);

                Assert.False(Db.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Any(_ => _.Id == existingId));
                Assert.True(Db.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Any(_ => _.Id == existingId + 1));
                Assert.True(Db.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Any(_ => _.Id == existingId + 2));
            }

            [Fact]
            public void ThrowsExceptionWhenNotFound()
            {
                Assert.Throws<HttpException>(() => { new EventCategoryPicklistMaintenance(Db, _lastInternalCodeGenerator).Delete(999); });
            }
        }
    }
}