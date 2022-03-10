using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Configuration.RecordalType;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using NSubstitute;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.RecordalTypes
{
    public class RecordalTypesFixture : IFixture<Inprotech.Web.Configuration.RecordalType.RecordalTypes>
    {
        public RecordalTypesFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new Inprotech.Web.Configuration.RecordalType.RecordalTypes(db, PreferredCultureResolver);
        }
        public Inprotech.Web.Configuration.RecordalType.RecordalTypes Subject { get; set; }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
    }
    public class RecordalTypesFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnAllRecordalTypes()
        {
            var ev1 = new EventBuilder().Build().In(Db);
            var ac1 = new ActionBuilder().Build().In(Db);
            var rt1 = new RecordalType {Id = 1, RecordalTypeName = Fixture.String("Owner"), RequestEvent = ev1, RequestAction = ac1}.In(Db);
            var rt2 = new RecordalType {Id = 2, RecordalTypeName = Fixture.String("Agent"), RecordEvent = ev1, RecordAction = ac1}.In(Db);
            var f = new RecordalTypesFixture(Db);
            var result = (await f.Subject.GetRecordalTypes()).ToArray();
            Assert.Equal(2, result.Length);
            Assert.Equal(rt1.RecordalTypeName, result[0].RecordalType);
            Assert.Equal(ev1.Description, result[0].RequestEvent);
            Assert.Equal(ac1.Name, result[0].RequestAction);
            Assert.Equal(rt2.RecordalTypeName, result[1].RecordalType);
            Assert.Equal(ev1.Description, result[1].RecordalEvent);
            Assert.Equal(ac1.Name, result[1].RecordalAction);
        }

        [Fact]
        public async Task ShouldThrowExceptionWhenRecordalTypeNotFound()
        {
            var f = new RecordalTypesFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Delete(Fixture.Integer()));
            Assert.IsType<HttpResponseException>(exception);
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldDeleteRecordalType()
        {
            var rt1 = new RecordalType {Id = 1, RecordalTypeName = Fixture.String("Owner")}.In(Db);
            var f = new RecordalTypesFixture(Db);
            var result = await f.Subject.Delete(rt1.Id);
            Assert.Equal("success", result.Result);
        }
    }

    public class GetRecordalTypeForm : FactBase
    {
        [Fact]
        public async Task ShouldThrowExceptionWhenRecordalTypeNotFound()
        {
            var f = new RecordalTypesFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetRecordalTypeForm(Fixture.Integer()));
            Assert.IsType<HttpResponseException>(exception);
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldReturnRecordalTypeWithElements()
        {
            var ev1 = new EventBuilder().Build().In(Db);
            var ac1 = new ActionBuilder().Build().In(Db);
            var rt1 = new RecordalType {Id = 1, RecordalTypeName = Fixture.String("Owner"), RequestEvent = ev1, RequestAction = ac1}.In(Db);
            var e1 = new Element {Id = 1, Code = Fixture.String(), EditAttribute = "DIS", Name = "Current Name"}.In(Db);
            var e2 = new Element {Id = 1, Code = Fixture.String(), EditAttribute = "MAN", Name = "New Name"}.In(Db);
            var nt1 = new NameTypeBuilder().Build().In(Db);
            var rte1 = new RecordalElement {Id = 1, Element = e1, ElementId = e1.Id, EditAttribute = e1.EditAttribute, RecordalType = rt1, ElementLabel = "Current Name", TypeId = rt1.Id, NameType = nt1, NameTypeCode = nt1.NameTypeCode}.In(Db);
            var rte2= new RecordalElement {Id = 3, Element = e2, ElementId = e2.Id, EditAttribute = e2.EditAttribute, RecordalType = rt1, ElementLabel = "New Name", TypeId = rt1.Id, NameType = nt1, NameTypeCode = nt1.NameTypeCode}.In(Db);
            var f = new RecordalTypesFixture(Db);
            var result = await f.Subject.GetRecordalTypeForm(rt1.Id);
            Assert.Equal(rt1.RecordalTypeName , result.RecordalType);
            Assert.Equal(ac1.Name, rt1.RequestAction.Name);
            Assert.Equal(ev1.Description, rt1.RequestEvent.Description);
            Assert.Equal(2, result.Elements.Count());
            Assert.Equal(rte1.ElementLabel, result.Elements.First().ElementLabel);
            Assert.Equal(rte1.EditAttribute, result.Elements.First().Attribute);
            Assert.Equal(nt1.Name, result.Elements.First().NameType.Value);
            Assert.Equal(e1.Name, result.Elements.First().Element.Value);
        }

        [Fact]
        public async Task ShouldReturnRecordalElement()
        {
            var ev1 = new EventBuilder().Build().In(Db);
            var ac1 = new ActionBuilder().Build().In(Db);
            var rt1 = new RecordalType {Id = 1, RecordalTypeName = Fixture.String("Owner"), RequestEvent = ev1, RequestAction = ac1}.In(Db);
            var e1 = new Element {Id = 1, Code = Fixture.String(), EditAttribute = "DIS", Name = "Current Name"}.In(Db);
            var nt1 = new NameTypeBuilder().Build().In(Db);
            var rte1 = new RecordalElement {Id = 1, Element = e1, ElementId = e1.Id, EditAttribute = e1.EditAttribute, RecordalType = rt1, ElementLabel = "Current Name", TypeId = rt1.Id, NameType = nt1, NameTypeCode = nt1.NameTypeCode}.In(Db);
            var f = new RecordalTypesFixture(Db);
            var result = await f.Subject.GetRecordalElementForm(rte1.Id);
            Assert.Equal(rte1.ElementLabel, result.ElementLabel);
            Assert.Equal(rte1.EditAttribute, result.Attribute);
            Assert.Equal(nt1.Name, result.NameType.Value);
            Assert.Equal(e1.Name, result.Element.Value);
        }
    }

    public class SubmitRecordalType : FactBase
    {
        [Fact]
        public async Task ShouldThrowExceptionWhenRecordalTypeModelNotFound()
        {
            var f = new RecordalTypesFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SubmitRecordalTypeForm(null));
            Assert.IsType<HttpResponseException>(exception);
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldReturnDuplicateError()
        {
            var rt1 = new RecordalType {Id = 1, RecordalTypeName = Fixture.String("Owner")}.In(Db);
            var f = new RecordalTypesFixture(Db);
            var model = new RecordalTypeRequest
            {
                RecordalType = rt1.RecordalTypeName
            };
            var result = (Inprotech.Infrastructure.Validations.ValidationError)await f.Subject.SubmitRecordalTypeForm(model);
            Assert.Equal("field.errors.duplicateRecordalType", result.Message);
        }

        [Fact]
        public async Task ShouldAddNewRecordalType()
        {
            var ev1 = new EventBuilder().Build().In(Db);
            var ac1 = new ActionBuilder().Build().In(Db);
            var nt1 = new NameTypeBuilder().Build().In(Db);
            var e1 = new Element {Id = 1, Code = Fixture.String(), EditAttribute = "DIS", Name = "Current Name"}.In(Db);
            var f = new RecordalTypesFixture(Db);
            var model = new RecordalTypeRequest
            {
                RecordalType = "Change of Owner",
                RequestEvent = ev1.Id,
                RequestAction = ac1.Code,
                Status = KnownModifyStatus.Add,
                Elements = new []
                {
                    new RecordalElementRequest
                    {
                        ElementLabel = Fixture.String(),
                        Attribute = "MAN",
                        NameType = nt1.NameTypeCode,
                        Element = e1.Id,
                        Status = KnownModifyStatus.Add
                    }
                }
            };

            var result = await f.Subject.SubmitRecordalTypeForm(model);
            Assert.NotNull(result);
            Assert.Equal(2, result.Id);
            var rt1 = Db.Set<RecordalType>().First();
            Assert.Equal(model.RecordalType, rt1.RecordalTypeName);
            Assert.Equal(model.RequestEvent, rt1.RequestEventId);
            Assert.Equal(model.RequestAction, rt1.RequestActionId);
            var rte1 = Db.Set<RecordalElement>().First();
            Assert.Equal(model.Elements.First().ElementLabel, rte1.ElementLabel);
            Assert.Equal(model.Elements.First().Attribute, rte1.EditAttribute);
            Assert.Equal(model.Elements.First().NameType, rte1.NameTypeCode);
        }

        [Fact]
        public async Task ShouldEditRecordalType()
        {
            var ev1 = new EventBuilder().Build().In(Db);
            var ac1 = new ActionBuilder().Build().In(Db);
            var nt1 = new NameTypeBuilder().Build().In(Db);
            var rt1 = new RecordalType {Id = 1, RecordalTypeName = Fixture.String("Owner"), RequestEvent = ev1, RequestAction = ac1}.In(Db);
            var e1 = new Element {Id = 1, Code = Fixture.String(), EditAttribute = "DIS", Name = "Current Name"}.In(Db);
            var e2 = new Element {Id = 2, Code = Fixture.String(), EditAttribute = "MAN", Name = "New Name"}.In(Db);
            var rte1 = new RecordalElement {Id = 1, Element = e1, ElementId = e1.Id, EditAttribute = e1.EditAttribute, RecordalType = rt1, ElementLabel = "Current Name", TypeId = rt1.Id, NameType = nt1, NameTypeCode = nt1.NameTypeCode}.In(Db);
            var f = new RecordalTypesFixture(Db);
            var model = new RecordalTypeRequest
            {
                Id = rt1.Id,
                RecordalType = "Change of Owner",
                Status = KnownModifyStatus.Edit,
                Elements = new []
                {
                    new RecordalElementRequest
                    {
                        ElementLabel = Fixture.String(),
                        Attribute = "MAN",
                        NameType = nt1.NameTypeCode,
                        Element = e2.Id,
                        Status = KnownModifyStatus.Add
                    },
                    new RecordalElementRequest
                    {
                        Id = rte1.Id,
                        ElementLabel = Fixture.String(),
                        Attribute = "DIS",
                        NameType = nt1.NameTypeCode,
                        Element = e1.Id,
                        Status = KnownModifyStatus.Edit
                    }
                }
            };

            var result = await f.Subject.SubmitRecordalTypeForm(model);
            Assert.NotNull(result);
            Assert.Equal(rte1.Id, result.Id);
            Assert.Equal(model.RecordalType, rt1.RecordalTypeName);
            var rte2 = Db.Set<RecordalElement>().First(_ => _.ElementId == e2.Id);
            Assert.Equal(model.Elements.First().ElementLabel, rte2.ElementLabel);
            Assert.Equal(model.Elements.First().Attribute, rte2.EditAttribute);
            Assert.Equal(model.Elements.First().NameType, rte2.NameTypeCode);
            Assert.Equal(model.Elements.Last().ElementLabel, rte1.ElementLabel);
            Assert.Equal(model.Elements.Last().Attribute, rte1.EditAttribute);
            Assert.Equal(model.Elements.Last().NameType, rte1.NameTypeCode);
        }
    }
}
