using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Names.Maintenance.Models;
using Inprotech.Web.Names.Maintenance.Validators;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Maintenance.Validators
{
    public class SupplierDetailsTopicValidatorFacts : FactBase
    {
        [Fact]
        public void DoesNotHaveAccessToTaskSecurityReturnsValidatorError()
        {
            var fixture = new SupplierDetailsTopicValidatorFixture();
            fixture.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(false);

            var validationErrors = fixture.Subject.Validate(null, null, null);

            Assert.Equal(1, validationErrors.Count());
        }

        [Fact]
        public void IfHasAccessToTaskContinuesOn()
        {
            var fixture = new SupplierDetailsTopicValidatorFixture();
            fixture.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(true);
            var name = new NameBuilder(Db).Build().In(Db);
            var supplierDetailModel = JObject.FromObject(new SupplierDetailsSaveModel() { SupplierType = Fixture.String()});
            var validationErrors = fixture.Subject.Validate(supplierDetailModel, null, name);

            Assert.Equal(1, validationErrors.Count());
        }

        [Fact]
        public void IfHasAccessToTaskAndRestrictionKeySelectedOn()
        {
            var fixture = new SupplierDetailsTopicValidatorFixture();
            fixture.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(true);
            var name = new NameBuilder(Db).Build().In(Db);
            var supplierDetailModel = JObject.FromObject(new SupplierDetailsSaveModel() { SupplierType = Fixture.String(), RestrictionKey = Fixture.String()});
            var validationErrors = fixture.Subject.Validate(supplierDetailModel, null, name);

            Assert.Equal(2, validationErrors.Count());
        }

        public class SupplierDetailsTopicValidatorFixture : IFixture<SupplierDetailsTopicValidator>
        {
            public SupplierDetailsTopicValidatorFixture()
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Subject = new SupplierDetailsTopicValidator(TaskSecurityProvider);
            }
            public SupplierDetailsTopicValidator Subject { get; }
            public ITaskSecurityProvider TaskSecurityProvider { get; }
        }
    }
}
