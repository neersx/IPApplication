using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Cases.Maintenance.Validators;
using Inprotech.Web.CaseSupportData;
using Newtonsoft.Json.Linq;
using NSubstitute;
using System.Collections.Generic;
using System.Linq;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Web.Cases.Maintenance.Validators
{
    public class DesignElementsTopicValidatorFacts : FactBase
    {
        [Fact]
        public void ShouldNotReturnErrorWhenNoFirmElementsAreDuplicate()
        {
            var f = new DesignElementsTopicValidatorFixture();
            var @case = new Case().In(Db);

            var saveModel = new DesignElementSaveModel
            {
                Rows = new[]
                {
                    new DesignElementData
                    {
                        Sequence = 2,
                        FirmElementCaseRef = Fixture.String("Firm3")
                    }
                }
            };

            f.DesignElements.ValidateDesignElements(@case, saveModel.Rows[0], saveModel.Rows).Returns(new List<ValidationError>());

            var saveModelJObject = JObject.FromObject(saveModel);
            var validationErrors = f.Subject.Validate(saveModelJObject, null, @case).ToArray();
            Assert.Equal(0, validationErrors.Length);
        }
        [Fact]
        public void ShouldReturnValidationErrorWhenSomeElemsAreDuplicate()
        {
            var f = new DesignElementsTopicValidatorFixture();
            var @case = new Case().In(Db);
            var firmElem = Fixture.String();

            var saveModel = new DesignElementSaveModel
            {
                Rows = new[]
                {
                    new DesignElementData
                    {
                        RowKey = "2",
                        Sequence = 2,
                        FirmElementCaseRef = firmElem
                    },
                    new DesignElementData
                    {
                        RowKey = "3",
                        Sequence = 3,
                        FirmElementCaseRef = Fixture.String("Firm3")
                    }
                }
            };
            f.DesignElements.ValidateDesignElements(Arg.Any<Case>(), Arg.Any<DesignElementData>(), Arg.Any<DesignElementData[]>()).Returns(new List<ValidationError>
            {
                new ValidationError(KnownCaseMaintenanceTopics.DesignElements, DesignElementsInputNames.FirmElementId, "2", Fixture.String())
            });

            var saveModelJObject = JObject.FromObject(saveModel);
            var validationErrors = f.Subject.Validate(saveModelJObject, null, @case).ToArray();
            Assert.Equal(2, validationErrors.Length);
            Assert.Equal(KnownCaseMaintenanceTopics.DesignElements, validationErrors[0].Topic);
            Assert.Equal(DesignElementsInputNames.FirmElementId, validationErrors[0].Field);
            Assert.Equal(saveModel.Rows[0].RowKey, validationErrors[0].Id);
        }

        public class DesignElementsTopicValidatorFixture : IFixture<DesignElementsTopicValidator>
        {
            public DesignElementsTopicValidatorFixture()
            {
                DesignElements = Substitute.For<IDesignElements>();
                Subject = new DesignElementsTopicValidator(DesignElements);
            }

            public DesignElementsTopicValidator Subject { get; }
            public IDesignElements DesignElements { get; }
        }
    }
}
