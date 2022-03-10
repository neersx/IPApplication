using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Web.Cases.Details;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class IppAvailabilityControllerFacts
    {
        readonly IFileSettingsResolver _fileSettingsResolver = Substitute.For<IFileSettingsResolver>();
        readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public void ShouldReturnWhetherCaseIsEnabledForViewing(bool hasViewFileCasePermission, bool expectedViewability)
        {
            var caseKey = Fixture.Integer();

            _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateFileCase).Returns(Fixture.Boolean());
            _fileSettingsResolver.Resolve().Returns(new FileSettings
            {
                IsEnabled = true
            });
            
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewFileCase).Returns(hasViewFileCasePermission);

            var subject = new IppAvailabilityController(_taskSecurityProvider, _fileSettingsResolver);

            var r = subject.GetAvailability(caseKey);

            Assert.Equal(expectedViewability, r.File.HasViewAccess);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public void ShouldReturnWhetherCaseIsEnabledForFilingInFile(bool hasCreateFileCasePermission, bool expectedCreatability)
        {
            var caseKey = Fixture.Integer();

            _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewFileCase).Returns(Fixture.Boolean());
            _fileSettingsResolver.Resolve().Returns(new FileSettings
            {
                IsEnabled = true
            });
            
            _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateFileCase).Returns(hasCreateFileCasePermission);

            var subject = new IppAvailabilityController(_taskSecurityProvider, _fileSettingsResolver);

            var r = subject.GetAvailability(caseKey);

            Assert.Equal(expectedCreatability, r.File.HasInstructAccess);
        }

        [Fact]
        public void ShouldReturnWhetherSiteIsEnabledForFile()
        {
            var fileSettings = new FileSettings
            {
                IsEnabled = Fixture.Boolean()
            };

            _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewFileCase).Returns(true);
            _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateFileCase).Returns(true);
            _fileSettingsResolver.Resolve().Returns(fileSettings);
            
            var subject = new IppAvailabilityController(_taskSecurityProvider, _fileSettingsResolver);

            var r = subject.GetAvailability(Fixture.Integer());

            Assert.Equal(fileSettings.IsEnabled, r.File.IsEnabled);
        }
    }
}