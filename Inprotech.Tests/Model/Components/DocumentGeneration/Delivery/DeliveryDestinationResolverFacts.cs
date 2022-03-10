using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.DocumentGeneration.Delivery
{
    public class DeliveryDestinationResolverFacts : FactBase
    {
        readonly IDeliveryDestinationStoredProcedureRunner _runner = Substitute.For<IDeliveryDestinationStoredProcedureRunner>();

        DeliveryDestinationResolver CreateSubject()
        {
            return new DeliveryDestinationResolver(Db, _runner);
        }

        [Fact]
        public async Task ShouldReturnFileDestinationIfConfigured()
        {
            var fileDestination = Fixture.String();

            var deliveryLetter = new Document
            {
                DeliveryMethodId = new DeliveryMethod
                {
                    FileDestination = fileDestination
                }.In(Db).Id
            }.In(Db);

            var subject = CreateSubject();

            var result = await subject.Resolve(Fixture.Integer(), Fixture.Integer(), deliveryLetter.Id);

            Assert.Equal(fileDestination, result.DirectoryName);
        }

        [Fact]
        public async Task ShouldReturnResultOfStoredProcedureIfConfigured()
        {
            var storedProcedureName = Fixture.String();

            var deliveryLetter = new Document
            {
                DeliveryMethodId = new DeliveryMethod
                {
                    DestinationStoredProcedure = storedProcedureName
                }.In(Db).Id
            }.In(Db);

            var returned = new DeliveryDestination();

            _runner.Run(Arg.Any<int?>(),Arg.Any<int?>(), deliveryLetter.Id, Arg.Any<int>(), storedProcedureName)
                   .Returns(returned);

            var subject = CreateSubject();

            var result = await subject.Resolve(Fixture.Integer(), Fixture.Integer(), deliveryLetter.Id);

            Assert.Equal(returned, result);
        }

        [Fact]
        public async Task ShouldReturnEmptyIfNotConfigured()
        {
            var deliveryLetter = new Document
            {
                DeliveryMethodId = new DeliveryMethod().In(Db).Id
            }.In(Db);

            var subject = CreateSubject();

            var result = await subject.Resolve(Fixture.Integer(), Fixture.Integer(), deliveryLetter.Id);

            Assert.Null(result.DirectoryName);
            Assert.Null(result.FileName);
        }
    }
}