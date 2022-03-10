using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Cases.Maintenance.Validators;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance.Validators
{
    public class FileLocationsTopicValidatorFacts : FactBase
    {
        FileLocationsSaveModel SetupFileLocation()
        {
            return new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FileLocationId = Fixture.Short(),
                        WhenMoved = Fixture.Date(),
                        FilePartId = Fixture.Short()
                    }
                }
            };
        }

        [Fact]
        public void ShouldNotReturnErrorWhenNoDuplicateCombinationExists()
        {
            var f = new FileLocationsTopicValidatorFixture();
            var @case = new Case().In(Db);
            var saveModel = SetupFileLocation();

            f.FileLocations.ValidateFileLocations(@case, saveModel.Rows[0], saveModel.Rows).Returns(new List<ValidationError>());

            var saveModelJObject = JObject.FromObject(saveModel);
            var validationErrors = f.Subject.Validate(saveModelJObject, null, @case).ToArray();
            Assert.Equal(0, validationErrors.Length);
        }

        [Fact]
        public void ShouldReturnErrorWhenDuplicateCombinationExists()
        {
            var f = new FileLocationsTopicValidatorFixture();
            var @case = new Case().In(Db);
            var saveModel = SetupFileLocation();

            f.FileLocations.ValidateFileLocationsOnSave(Arg.Any<Case>(), Arg.Any<FileLocationsData>(), Arg.Any<FileLocationsData[]>()).Returns(new List<ValidationError>
            {
                new ValidationError(KnownCaseMaintenanceTopics.FileLocations, FileLocationsInputNames.FileLocation, "1", Fixture.String())
            });

            var saveModelJObject = JObject.FromObject(saveModel);
            var validationErrors = f.Subject.Validate(saveModelJObject, null, @case).ToArray();

            Assert.Equal(1, validationErrors.Length);
            Assert.Equal("fileLocation", validationErrors[0].Field);
            Assert.Equal("fileLocations", validationErrors[0].Topic);
        }

        [Fact]
        public void ShouldReturnFileRequestError()
        {
            var f = new FileLocationsTopicValidatorFixture();
            var @case = new Case().In(Db);
            new FileRequest
            {
                FileLocationId = Fixture.Short(),
                DateRequired = Fixture.Date(),
                Status = 0,
                SequenceNo = Fixture.Short(),
                CaseId = @case.Id,
                FilePartId = Fixture.Short()
            }.In(Db);

            var saveModel = SetupFileLocation();

            f.FileLocations.ValidateFileLocationsOnSave(Arg.Any<Case>(), Arg.Any<FileLocationsData>(), Arg.Any<FileLocationsData[]>()).Returns(new List<ValidationError>
            {
                new ValidationError(KnownCaseMaintenanceTopics.FileLocations, FileLocationsInputNames.ActiveFileRequest, "1", Fixture.String())
            });

            var saveModelJObject = JObject.FromObject(saveModel);
            var validationErrors = f.Subject.Validate(saveModelJObject, null, @case).ToArray();
            Assert.Equal(1, validationErrors.Length);
            Assert.Equal("activeFileRequest", validationErrors[0].Field);
            Assert.Equal("fileLocations", validationErrors[0].Topic);
        }

        public class FileLocationsTopicValidatorFixture : IFixture<FileLocationsTopicValidator>
        {
            public FileLocationsTopicValidatorFixture()
            {
                FileLocations = Substitute.For<IFileLocations>();
                Subject = new FileLocationsTopicValidator(FileLocations);
            }

            public FileLocationsTopicValidator Subject { get; }
            public IFileLocations FileLocations { get; }
        }
    }
}
